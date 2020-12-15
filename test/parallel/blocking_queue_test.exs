defmodule Parallel.BlockingQueueTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = Parallel.BlockingQueue.start_link()
    {:ok, bq: pid}
  end

  test "BlockingQueue should be FIFO", %{bq: pid} do
    Parallel.BlockingQueue.enqueue(pid, 1)
    Parallel.BlockingQueue.enqueue(pid, 2)
    Parallel.BlockingQueue.enqueue(pid, 3)
    assert 1 == Parallel.BlockingQueue.dequeue(pid)
    assert 2 == Parallel.BlockingQueue.dequeue(pid)
    assert 3 == Parallel.BlockingQueue.dequeue(pid)
  end

  test "BlockingQueue.dequeue/1 should block when the queue is empty", %{bq: pid} do
    # Spawn a process that pushes an item to the queue 6 seconds later
    spawn_link(fn ->
      # sleep 6 seconds
      Process.sleep(6_000)
      Parallel.BlockingQueue.enqueue(pid, "Hi")
    end)

    {time, _} =
      :timer.tc(fn ->
        assert "Hi" == Parallel.BlockingQueue.dequeue(pid)
      end)

    # `dequeue` should block more than 5 seconds (which is the default timeout for GenServer.call)
    assert time > 5_000_000
  end
end
