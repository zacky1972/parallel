defmodule Parallel.Pool do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_process() do
    GenServer.call(__MODULE__, :get_process)
  end

  def alive(pid) do
    GenServer.cast(__MODULE__, {:alive, pid})
  end

  @impl true
  def init(pool) do
    {:ok, {pool, 0}}
  end

  @impl true
  def handle_call(:get_process, _from, {[], wid}) do
    {:reply, Parallel.Worker_2.create_process(wid), {[], wid + 1}}
  end

  def handle_call(:get_process, _from, {[head | tail], wid}) do
    {:reply, head, {tail, wid}}
  end

  @impl true
  def handle_cast({:alive, pid}, {pool, wid}) do
    {:noreply, {pool ++ [pid], wid}}
  end
end
