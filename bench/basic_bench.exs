defmodule BasicBench do
  use Benchfella

  @range_0x10000 (1..0x10000)

  bench "Enum" do
    @range_0x10000
    |> Enum.map(&(&1 * &1))
  end

  bench "Pmap" do
    @range_0x10000
    |> Parallel.pmap(&(&1 * &1))
  end

  bench "Pmap2" do
    @range_0x10000
    |> Parallel.pmap_2(&(&1 * &1))
  end
end