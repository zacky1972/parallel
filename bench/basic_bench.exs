defmodule BasicBench do
  use Benchfella

  @range_0x10000 Enum.to_list(1..0x10000)

  setup_all do
    Parallel.Application.start(nil, nil)
    Parallel.init()
    {:ok, nil}
  end

  def logistic_map(v) do
    rem(22 * v * (v + 1), 6_700_417)
  end

  def logistic_map_10(v) do
    logistic_map(v)
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
    |> logistic_map()
  end

  bench "Enum" do
    @range_0x10000
    |> Enum.map(& logistic_map_10(&1))
  end

  bench "Pmap" do
    @range_0x10000
    |> Parallel.pmap(& logistic_map_10(&1))
  end

  bench "Pmap2" do
    @range_0x10000
    |> Parallel.pmap_2(& logistic_map_10(&1))
  end

  bench "Pmap3" do
    @range_0x10000
    |> Parallel.pmap_3(& logistic_map_10(&1))
  end

  bench "Pmap4" do
    @range_0x10000
    |> Parallel.pmap_4(& logistic_map_10(&1))
  end

  bench "Flow" do
    @range_0x10000
    |> Flow.from_enumerable()
    |> Flow.map(& logistic_map_10(&1))
    |> Enum.sort()
  end    
end