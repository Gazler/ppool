defmodule PPool.Supervisor do
  use Supervisor

  def start_link(name, limit, mfa) do
    Supervisor.start_link(__MODULE__, {name, limit, mfa})
  end

  def init({name, limit, mfa}) do
    children = [
      worker(PPool.Server, [name, limit, self, mfa])
    ]
    supervise(children, strategy: :one_for_all)
  end
end
