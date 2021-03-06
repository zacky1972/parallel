defmodule Parallel.MixProject do
  use Mix.Project

  def project do
    [
      app: :parallel,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Parallel.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchfella, "~> 0.3.5"},
      {:flow, "~> 1.0.0"},
      {:pelemay, "~> 0.0.14"},
      {:cpu_info, "~> 0.2.1"}
    ]
  end
end
