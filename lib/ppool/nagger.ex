defmodule PPool.Nagger do
  use GenServer

  def start_link(task, delay, max, send_to) do
    GenServer.start_link(__MODULE__, {task, delay, max, send_to})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(state = {_task, delay, _max, _send_to}) do
    {:ok, state, delay}
  end

  def handle_info(:timeout, state = {task, delay, max, send_to}) do
    send(send_to, {self, task})
    cond do
      max == :infinity -> {:noreply, state, delay}
      max <= 1         -> {:stop, :normal, {task, delay, 0, send_to}}
      max > 1          -> {:noreply, {task, delay, max - 1, send_to}, delay}
    end
  end
end
