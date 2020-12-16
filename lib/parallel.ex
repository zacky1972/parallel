defmodule Parallel do
  @threshold 2000

  def init do
    1..:erlang.system_info(:logical_processors_available)
    |> Enum.each(fn _ ->  Parallel.Pool.get_process() end)
  end

  def pmap(collection, func) do
    collection
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  def pmap_2(collection, func) when is_list(collection) do
    pmap_2_sub(collection, [], func, 0, @threshold)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
    |> Enum.reverse()
  end

  def pmap_2(collection, func) do
    collection |> Enum.to_list() |> pmap_2(func)
  end

  defp pmap_2_sub([], rest, func, _, _) do
    [Task.async(fn -> Enum.map(rest, func) end)]
  end

  defp pmap_2_sub(rest, heads, func, threshold, threshold) do
    [
      Task.async(fn -> Enum.map(heads, func) end)
      | pmap_2_sub(rest, [], func, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  defp pmap_2_sub([head | tail], heads, func, count, threshold) do
    pmap_2_sub(tail, [head | heads], func, count + 1, threshold)
  end

  def pmap_3(collection, func) when is_list(collection) do
    pmap_3_sub(collection, [], func, 0, 0, @threshold)
    |> receive_result([])
    |> Enum.map(fn {_, fragment} -> fragment end)
    |> List.flatten()
    |> Enum.reverse()
  end

  def pmap_3(collection, func) do
    collection |> Enum.to_list() |> pmap_3(func)
  end

  def receive_result([], result_list) do
    result_list
  end

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
      500 -> raise "Timeout when Process.receive_result/2"
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

  def pmap_4(collection, func) when is_list(collection) do
    pmap_4_sub(collection, [], func, 0, 0, @threshold)
    |> receive_result([])
    |> Enum.map(fn {_, fragment} -> fragment end)
    |> List.flatten()
    |> Enum.reverse()
  end

  def pmap_4(collection, func) do
    collection |> Enum.to_list() |> pmap_4(func)
  end

  def pmap_4_sub([], rest, func, id, _, _) do
    Parallel.Pool.get_process() |> call(self(), id, rest, func)
    [id]
  end

  def pmap_4_sub(rest, heads, func, id, threshold, threshold) do
    Parallel.Pool.get_process() |> call(self(), id, heads, func)
    [
      id
      | pmap_4_sub(rest, [], func, id + 1, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_4_sub([head | tail], heads, func, id, count, threshold) do
    pmap_4_sub(tail, [head | heads], func, id, count + 1, threshold)
  end

  def call(wpid, rpid, id, fragment, func) do
    send(wpid, {:work, rpid, id, fragment, func})
    wpid
  end
end
