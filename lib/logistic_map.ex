defmodule LogisticMap do
  import Pelemay

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

  defpelemay do
    def logistic_map_10_pelemay(list) do
      list
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
      |> Enum.map(& rem(22 * &1 * (&1 + 1), 6_700_417))
    end
  end
end
