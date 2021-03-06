defmodule Parallel do
  @threshold 1_000

  def init do
    1..(CpuInfo.all_profile() |> Map.get(:cpu) |> Map.get(:total_num_of_threads))
    |> Enum.each(fn _ -> Parallel.Pool.get_process() end)
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
    Parallel.Pool.get_process() |> call(self(), id, rest, &Enum.map(&1, func))
    [id]
  end

  def pmap_4_sub(rest, heads, func, id, threshold, threshold) do
    Parallel.Pool.get_process() |> call(self(), id, heads, &Enum.map(&1, func))

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

  def pmap_5(collection, func) when is_list(collection) do
    pmap_5_sub(collection, [], func, 0, 0, @threshold)
    |> receive_result([])
    |> Enum.map(fn {_, fragment} -> fragment end)
    |> List.flatten()
    |> Enum.reverse()
  end

  def pmap_5(collection, func) do
    collection |> Enum.to_list() |> pmap_5(func)
  end

  def pmap_5_sub([], rest, func, id, _, _) do
    Parallel.Pool.get_process() |> call(self(), id, rest, func)
    [id]
  end

  def pmap_5_sub(rest, heads, func, id, threshold, threshold) do
    Parallel.Pool.get_process() |> call(self(), id, heads, func)

    [
      id
      | pmap_5_sub(rest, [], func, id + 1, 0, threshold) |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_5_sub([head | tail], heads, func, id, count, threshold) do
    pmap_5_sub(tail, [head | heads], func, id, count + 1, threshold)
  end

  def pmap_f(
        collection,
        func,
        opts \\ [chunk_mode: false, spawn_mode: :spawn, result_mode: :enum]
      ) do
    pmap_chunk_every_to_spawn_func(collection, @threshold, func, nil, opts)
    |> receive_result_with_opt(opts)
    |> Enum.map(fn {fragment, _} -> fragment end)
    |> List.flatten()
    |> Enum.reverse()
  end

  def pmap_chunk_every_to_spawn_func(collection, count, func, spawn_func, opts) do
    case {
      Keyword.get(opts, :chunk_mode),
      Keyword.get(opts, :spawn_mode),
      spawn_func,
      opts
    } do
      {false, _, _, opts} ->
        pmap_chunk_every_to_spawn_func(
          collection,
          count,
          &Enum.map(&1, func),
          spawn_func,
          Keyword.put(opts, :chunk_mode, true)
        )

      {true, :spawn, nil, opts} ->
        pmap_chunk_every_to_spawn_func(
          collection,
          count,
          func,
          fn pid, id, heads, func ->
            Parallel.Pool.get_process() |> call(pid, id, heads, func)
          end,
          opts
        )

      {true, _, spawn_func, _opts} ->
        pmap_chunk_every_to_spawn_func_sub(
          collection,
          [],
          func,
          spawn_func,
          0,
          0,
          count
        )
    end
  end

  def pmap_chunk_every_to_spawn_func_sub(n..n, rest, func, spawn_func, id, _, _) do
    spawn_func.(self(), id, rest, func)
    [id]
  end

  def pmap_chunk_every_to_spawn_func_sub([], rest, func, spawn_func, id, _, _) do
    spawn_func.(self(), id, rest, func)
    [id]
  end

  def pmap_chunk_every_to_spawn_func_sub(from..to, [], func, spawn_func, id, 0, threshold)
      when from < to and from + threshold - 1 < to do
    spawn_func.(self(), id, (from + threshold - 1)..from, func)

    [
      id
      | pmap_chunk_every_to_spawn_func_sub(
          (from + threshold)..to,
          [],
          func,
          spawn_func,
          id + 1,
          0,
          threshold
        )
        |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_chunk_every_to_spawn_func_sub(from..to, [], func, spawn_func, id, 0, threshold)
      when from < to and from + threshold - 1 >= to do
    spawn_func.(self(), id, to..from, func)
    [id]
  end

  def pmap_chunk_every_to_spawn_func_sub(from..to, [], func, spawn_func, id, 0, threshold)
      when from > to and from - threshold + 1 > to do
    spawn_func.(self(), id, (from - threshold + 1)..from, func)

    [
      id
      | pmap_chunk_every_to_spawn_func_sub(
          (from - threshold)..to,
          [],
          func,
          spawn_func,
          id + 1,
          0,
          threshold
        )
        |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_chunk_every_to_spawn_func_sub(from..to, [], func, spawn_func, id, 0, threshold)
      when from > to and from - threshold + 1 <= to do
    spawn_func.(self(), id, to..from, func)
    [id]
  end

  def pmap_chunk_every_to_spawn_func_sub(rest, heads, func, spawn_func, id, threshold, threshold) do
    spawn_func.(self(), id, heads, func)

    [
      id
      | pmap_chunk_every_to_spawn_func_sub(
          rest,
          [],
          func,
          spawn_func,
          id + 1,
          0,
          threshold
        )
        |> Enum.reverse()
    ]
    |> Enum.reverse()
  end

  def pmap_chunk_every_to_spawn_func_sub(
        [head | tail],
        heads,
        func,
        spawn_func,
        id,
        count,
        threshold
      ) do
    pmap_chunk_every_to_spawn_func_sub(
      tail,
      [head | heads],
      func,
      spawn_func,
      id,
      count + 1,
      threshold
    )
  end

  def receive_result_with_opt(id_list, opts) do
    case Keyword.get(opts, :result_mode, :enum) do
      :enum -> receive_result_enum(id_list, [])
      :merge -> receive_result_merge(id_list, [])
      :merge_2 -> receive_result_merge_2(id_list, []) |> Enum.reverse()
      :bin -> receive_result_bin(id_list, nil) |> binary_to_list()
    end
  end

  def receive_result_enum([], result_list) do
    result_list
  end

  def receive_result_enum(id_list, result_list) do
    receive do
      {id, fragment} ->
        receive_result_enum(
          List.delete(id_list, id),
          (result_list ++ [{fragment, id}])
          |> Enum.sort(fn {_f1, id1}, {_f2, id2} -> id1 >= id2 end)
        )
    after
      500 -> raise "Timeout when Process.receive_result/2"
    end
  end

  def receive_result_merge([], result_list) do
    result_list
  end

  def receive_result_merge(id_list, result_list) do
    receive do
      {id, fragment} ->
        receive_result_merge(
          List.delete(id_list, id),
          merge(result_list, {fragment, id})
        )
    after
      500 -> raise "Timeout when Process.receive_result/2"
    end
  end

  def merge([], {fragment, id}) do
    [{fragment, id}]
  end

  def merge([{f_r, id_r} | rest], {fragment, id}) do
    if id_r >= id do
      [{f_r, id_r} | merge(rest, {fragment, id})]
    else
      [{fragment, id} | [{f_r, id_r} | rest]]
    end
  end

  def receive_result_merge_2([], result_list) do
    result_list
  end

  def receive_result_merge_2(id_list, result_list) do
    receive do
      {id, fragment} ->
        receive_result_merge_2(
          List.delete(id_list, id),
          merge_2(result_list, {fragment, id})
        )
    after
      500 -> raise "Timeout when Process.receive_result/2"
    end
  end

  def merge_2([], {fragment, id}) do
    [{fragment, id}]
  end

  def merge_2([{f_r, id_r} | rest], {fragment, id}) do
    if id_r < id do
      [{f_r, id_r} | merge(rest, {fragment, id})]
    else
      [{fragment, id} | [{f_r, id_r} | rest]]
    end
  end

  def receive_result_bin([], result_bin) do
    result_bin
  end

  def receive_result_bin(id_list, result_bin) do
    receive do
      {id, fragment} ->
        receive_result_bin(
          List.delete(id_list, id),
          bin_merge(result_bin, {id, fragment})
        )
    after
      500 -> raise "Timeout when Process.receive_result/2"
    end
  end

  def bin_merge(nil, {id, fragment}) do
    {id, fragment, nil, nil}
  end

  def bin_merge({id_r, fragment_r, left, right}, {id, fragment}) do
    cond do
      id_r < id -> {id_r, fragment_r, bin_merge(left, {id, fragment}), right}
      true -> {id_r, fragment_r, left, bin_merge(right, {id, fragment})}
    end
  end

  def binary_to_list(nil), do: []

  def binary_to_list({_id, fragment, left, right}) do
    binary_to_list(left) ++ fragment ++ binary_to_list(right)
  end
end
