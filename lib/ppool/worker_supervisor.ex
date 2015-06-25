defmodule PPool.WorkerSupervisor do
  use Supervisor

  def start_link(mfa) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  def init({module, function, args}) do
    children = [
      worker(module, args, restart: :temporary, function: function)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end
