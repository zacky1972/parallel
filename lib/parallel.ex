defmodule Parallel do
  def pmap(collection, func) do
    collection
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  def pmap_2(collection, func) do
    pmap_2_sub(Enum.to_list(collection), [], func, 0, 2000)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
    |> Enum.reverse()
  end

  defp pmap_2_sub([], rest, func, _, _) do
    [Task.async(fn -> Enum.map(rest, func) end)]
  end

  defp pmap_2_sub(rest, heads, func, threshold, threshold) do
    [
      Task.async(fn -> heads |> Enum.map(func) end)
      | pmap_2_sub(rest, [], func, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  defp pmap_2_sub([head | tail], heads, func, count, threshold) do
    pmap_2_sub(tail, [head | heads], func, count + 1, threshold)
  end

  def pmap_3(collection, func) do
    pmap_3_sub(Enum.to_list(collection), [], func, 0, 0, 20)
    |> receive_result([])
    |> Enum.map(fn {_, fragment} -> fragment end)
    |> List.flatten()
    |> Enum.reverse()
  end

  def receive_result([], result_list), do: result_list

  def receive_result(id_list, result_list) do
    receive do
      {id, fragment} ->
        receive_result(
          List.delete(id_list, id),
          Enum.sort(
            [{id, fragment} | result_list],
            fn {id1, _f1}, {id2, _f2} -> id1 >= id2 end
          )
        )
    after
      500 -> :error
    end
  end

  def pmap_3_sub([], rest, func, id, _, _) do
    Parallel.BlockingQueue.enqueue(:task_queue, {self(), id, rest, func})
    [id]
  end

  def pmap_3_sub(rest, heads, func, id, threshold, threshold) do
    Parallel.BlockingQueue.enqueue(:task_queue, {self(), id, heads, func})

    [
      id
      | pmap_3_sub(rest, [], func, id + 1, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_3_sub([head | tail], heads, func, id, count, threshold) do
    pmap_3_sub(tail, [head | heads], func, id, count + 1, threshold)
  end
end
