defmodule Parallel.Worker_2 do
  def worker(wid) do
    receive do
      {:work, pid, id, fragment, func} ->
        send(pid, {id, func.(fragment)})

        create_process(wid)
        |> Parallel.Pool.alive()
    end
  end

  def create_process(wid) do
    wpid = spawn(Parallel.Worker_2, :worker, [wid])
    :global.register_name(:"worker_#{wid}", wpid)
    wpid
  end
end
