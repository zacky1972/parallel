defmodule Parallel.Worker_2 do

  def worker(wid) do
    receive do
      {:work, pid, id, fragment, func} ->
        send(pid, {id, func.(fragment)})
        Parallel.Pool.alive(self())
        worker(wid)
    end
  end  
end