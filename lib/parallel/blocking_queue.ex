defmodule Parallel.BlockingQueue do
  use GenServer

  @empty_queue :queue.new()

  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def enqueue(blocking_queue, item) do
    GenServer.call(blocking_queue, {:enqueue, item})
  end

  def dequeue(blocking_queue) do
    GenServer.call(blocking_queue, :dequeue, :infinity)
  end

  @impl true
  def init(_items) do
    {
      :ok,
      {
        # items queue
        :queue.new(),
        # processes waiting for item
        :queue.new()
      }
    }
  end

  @impl true
  def handle_call({:enqueue, item}, _from, {items, refs}) do
    {
      :reply,
      :ok,
      {:queue.in(item, items), refs},
      {:continue, :dequeue}
    }
  end

  @impl true
  def handle_call(:dequeue, from, {items, refs}) do
    {
      :noreply,
      {items, :queue.in(from, refs)},
      {:continue, :dequeue}
    }
  end

  @impl true
  def handle_continue(_, {@empty_queue, _refs} = state) do
    {:noreply, state}
  end

  def handle_continue(_, {_items, @empty_queue} = state) do
    {:noreply, state}
  end

  def handle_continue(_, {items, refs}) do
    {{:value, item}, items} = :queue.out(items)
    {{:value, ref}, refs} = :queue.out(refs)
    GenServer.reply(ref, item)
    {:noreply, {items, refs}, {:continue, :dequeue}}
  end
end
