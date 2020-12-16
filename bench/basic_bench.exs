defmodule BasicBench do
  use Benchfella

  @range_0x10000 Enum.to_list(1..0x10000)

  setup_all do
    Parallel.Application.start(nil, nil)
    Parallel.init()
    LogisticMap.logistic_map_10_pelemay(1..0x10000)
    {:ok, nil}
  end

  bench "Enum" do
    @range_0x10000
    |> Enum.map(& LogisticMap.logistic_map_10(&1))
  end

  bench "Pmap" do
    @range_0x10000
    |> Parallel.pmap(& LogisticMap.logistic_map_10(&1))
  end

  bench "Pmap2" do
    @range_0x10000
    |> Parallel.pmap_2(& LogisticMap.logistic_map_10(&1))
  end

  bench "Pmap3" do
    @range_0x10000
    |> Parallel.pmap_3(& LogisticMap.logistic_map_10(&1))
  end

  bench "Pmap4" do
    @range_0x10000
    |> Parallel.pmap_4(& LogisticMap.logistic_map_10(&1))
  end

  bench "Flow" do
    @range_0x10000
    |> Flow.from_enumerable()
    |> Flow.map(& LogisticMap.logistic_map_10(&1))
    |> Enum.sort()
  end

  bench "Pelemay" do
    @range_0x10000
    |> LogisticMap.logistic_map_10_pelemay()
  end
end