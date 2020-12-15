defmodule Parallel do
  def pmap(collection, func) do
    collection
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end

  def pmap_2(collection, func) do
    pmap_sub(Enum.to_list(collection), [], func, 0, 2000)
    |> Enum.map(&Task.await/1)
    |> List.flatten()
    |> Enum.reverse()
  end

  defp pmap_sub([], rest, func, _, _) do
    [Task.async(fn -> Enum.map(rest, func) end)]
  end

  defp pmap_sub(rest, heads, func, threshold, threshold) do
    [
      Task.async(fn -> heads |> Enum.map(func) end)
      | pmap_sub(rest, [], func, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  defp pmap_sub([head | tail], heads, func, count, threshold) do
    pmap_sub(tail, [head | heads], func, count + 1, threshold)
  end
end
