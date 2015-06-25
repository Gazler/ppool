defmodule PPool.SuperSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :ppool)
  end

  def start_pool(name, limit, mfa) do
    Supervisor.start_child(:ppool, supervisor(PPool.Supervisor, [name, limit, mfa]))
  end

  def stop_pool(name) do
    Supervisor.terminate_child(:ppool, name)
    Supervisor.delete_child(:ppool, name)
  end

  def stop do
    case Process.whereis(:ppool) do
      pid when is_pid(pid) -> Process.exit(pid, :kill)
      _                    -> :ok
    end
  end

  def init([]) do
    children = []
    supervise(children, strategy: :one_for_one)
  end
end
