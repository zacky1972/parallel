defmodule BasicBench do
  use Benchfella

  @range_0x1000 (1..0x1000)

  bench "Enum" do
    @range_0x1000
    |> Enum.map(&(&1 * &1))
  end

  bench "Pmap" do
    @range_0x1000
    |> Parallel.pmap(&(&1 * &1))
  end
end