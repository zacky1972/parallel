defmodule BasicBench do
  use Benchfella

  @range_0x10000 Enum.to_list(1..0x10000)

  setup_all do
    Parallel.Application.start(nil, nil)
  end

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

  bench "Pmap3" do
    @range_0x10000
    |> Parallel.pmap_3(&(&1 * &1))
  end

  bench "Pmap4" do
    @range_0x10000
    |> Parallel.pmap_4(&(&1 * &1))
  end
end