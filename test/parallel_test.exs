defmodule ParallelTest do
  use ExUnit.Case
  doctest Parallel

  test "Pmap_f test 1" do
    assert Parallel.pmap_f(1..10000, &(&1 * 2)) == Enum.map(1..10000, &(&1 * 2))
  end

  test "Pmap_f test 2" do
    assert Parallel.pmap_f(1..10000 |> Enum.to_list(), &(&1 * 2)) == Enum.map(1..10000, &(&1 * 2))
  end

  test "Pmap_f bin test" do
    assert Parallel.pmap_f(1..10000, &(&1 * 2),
             spawn_mode: :spawn,
             chunk_mode: false,
             receive_mode: :bin
           ) == Enum.map(1..10000, &(&1 * 2))
  end
end
