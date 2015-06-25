defmodule PPool.Server do
  use GenServer

  def start(name, limit, supervisor, mfa) do
    GenServer.start(__MODULE__, {limit, mfa, supervisor}, name: name)
  end

  def start_link(name, limit, supervisor, mfa) do
    GenServer.start_link(__MODULE__, {limit, mfa, supervisor}, name: name)
  end

  def run(name, args) do
    GenServer.call(name, {:run, args})
  end

  def sync_queue(name, args) do
    GenServer.call(name, {:sync, args}, :infinity)
  end

  def async_queue(name, args) do
    GenServer.cast(name, {:async, args})
  end

  def stop(name) do
    GenServer.call(name, :stop)
  end

  def init({limit, mfa, supervisor}) do
    send(self, {:start_worker_supervisor, supervisor, mfa})
    {:ok, %{limit: limit, supervisor: supervisor, refs: HashSet.new, queue: []}}
  end

  def handle_call({:run, args}, _from, state = %{limit: limit, supervisor: supervisor, refs: refs}) when limit > 0 do
    {:ok, pid} = Supervisor.start_child(supervisor, args)
    ref = Process.monitor(pid)
    new_state =
      state
      |> Map.put(:limit, limit - 1)
      |> Map.put(:refs, HashSet.put(refs, ref))
    {:reply, {:ok, pid}, new_state}
  end

  def handle_call({:run, _}, _from, state) do
    {:reply, :noalloc, state}
  end

  def handle_call({:sync, args}, _from, state = %{limit: limit, supervisor: supervisor, refs: refs}) when limit > 0 do
    {:ok, pid} = Supervisor.start_child(supervisor, args)
    ref = Process.monitor(pid)
    new_state =
      state
      |> Map.put(:limit, limit - 1)
      |> Map.put(:refs, HashSet.put(refs, ref))
    {:reply, {:ok, pid}, new_state}
  end

  def handle_call({:sync, args}, from, state = %{queue: queue}) do
    {:noreply, %{state | queue: queue ++ [{from, args}]}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call(_, _from, state) do
    {:noreply, state}
  end

  def handle_cast({:async, args}, state = %{limit: limit, supervisor: supervisor, refs: refs}) when limit > 0 do
    {:ok, pid} = Supervisor.start_child(supervisor, args)
    ref = Process.monitor(pid)
    new_state =
      state
      |> Map.put(:limit, limit - 1)
      |> Map.put(:refs, HashSet.put(refs, ref))
    {:noreply, new_state}
  end

  def handle_cast({:async, args}, state = %{queue: queue, limit: limit}) do
    {:noreply, %{state | queue: queue ++ [args]}}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_info({:start_worker_supervisor, supervisor, mfa = {module, function, args}}, state) do
    {:ok, pid} = Supervisor.start_child(supervisor, Supervisor.Spec.supervisor(PPool.WorkerSupervisor, [mfa]))
    Process.link(pid)
    {:noreply, %{state | supervisor: pid}}
  end

  def handle_info({:'DOWN', ref, :process, _pid, _}, state = %{refs: refs}) do
    handle_down_worker(ref, state)
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp handle_down_worker(ref, state = %{limit: limit, refs: refs, queue: []}) do
    new_state =
      state
      |> Map.put(:refs, HashSet.delete(refs, ref))
      |> Map.put(:limit, limit + 1)
    {:noreply, new_state}
  end

  defp handle_down_worker(ref, state = %{limit: limit, supervisor: supervisor, refs: refs, queue: [head | tail]}) do
    new_state =
      state
      |> Map.put(:queue, tail)
      |> Map.put(:refs, HashSet.delete(refs, ref))
    case head do
      {from, args} ->
        {:ok, pid} = Supervisor.start_child(supervisor, args)
        new_ref = Process.monitor(pid)
        GenServer.reply(from, {:ok, pid})
        {:noreply, %{new_state | refs: HashSet.put(refs, new_ref)}}
      args ->
        {:ok, pid} = Supervisor.start_child(supervisor, args)
        new_ref = Process.monitor(pid)
        {:noreply, %{new_state | refs: HashSet.put(refs, new_ref)}}
    end
  end
end
