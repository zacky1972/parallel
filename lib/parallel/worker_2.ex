defmodule Parallel.Worker_2 do

  def worker(wid) do
    receive do
      {:work, pid, id, fragment, func} ->
        send(pid, {id, Enum.map(fragment, &func.(&1))})
        Parallel.Pool.alive(self())
        worker(wid)
    after
      1_000_000 ->
        :ok
    end
  end  
end