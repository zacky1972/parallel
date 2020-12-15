defmodule Parallel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Starts a worker by calling: Parallel.Worker.start_link(arg)
        # {Parallel.Worker, arg}
        {Parallel.BlockingQueue, name: :task_queue}
      ] ++
        (1..:erlang.system_info(:logical_processors_available)
         |> Enum.map(fn id -> Supervisor.child_spec(Parallel.Worker, id: :"worker_#{id}") end))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Parallel.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
