defmodule Parallel.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    Process.send_after(self(), :do_one_file, 0)
    {:ok, nil}
  end

  def handle_info(:do_one_file, _) do
    {pid, id, fragment, func} = Parallel.BlockingQueue.dequeue(:task_queue)
    send(pid, {id, Enum.map(fragment, &func.(&1))})
    send(self(), :do_one_file)
    {:noreply, nil}
  end
end
