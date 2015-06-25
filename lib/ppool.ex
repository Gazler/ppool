defmodule PPool do
  def start_link do
    PPool.SuperSupervisor.start_link
  end

  def stop do
    PPool.SuperSupervisor.stop
  end

  def start_pool(name, limit, mfa = {_m, _f, _a}) do
    PPool.SuperSupervisor.start_pool(name, limit, mfa)
  end

  def stop_pool(name) do
    PPool.SuperSupervisor.stop_pool(name)
  end

  def run(name, args) do
    PPool.Server.run(name, args)
  end

  def async_queue(name, args) do
    PPool.Server.async_queue(name, args)
  end

  def sync_queue(name, args) do
    PPool.Server.sync_queue(name, args)
  end
end
