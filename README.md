# Ppool

An Elixir port of http://learnyousomeerlang.com/building-applications-with-otp

## Usage

You can use the following functions:

 * `PPool.run/2` - Run if there are any workers available, otherwise do nothing.
 * `PPool.sync_queue/2` - Run if there are any workers available, otherwise block until a worker is ready.
 * `PPool.async_queue/2` - Run if there are any workers available, otherwise add the job to a queue.

    iex(1)> PPool.start_link
    {:ok, #PID<0.119.0>}
    iex(2)> PPool.start_pool(:nagger, 2, {PPool.Nagger, :start_link, []})
    {:ok, #PID<0.121.0>}
    iex(3)> PPool.run(:nagger, ["Finish the chapter!", 10000, 10, self])
    {:ok, #PID<0.125.0>}
    iex(4)> flush
    :ok
    iex(5)> flush
    {#PID<0.125.0>, "Finish the chapter!"}
    :ok
    iex(6)> PPool.run(:nagger, ["Watch a good movie", 10000, 10, self])
    {:ok, #PID<0.129.0>}
    iex(7)> PPool.run(:nagger, ["Clean up a bit", 10000, 10, self])
    :noalloc
    iex(8)> flush
    {#PID<0.125.0>, "Finish the chapter!"}
    {#PID<0.125.0>, "Finish the chapter!"}
    {#PID<0.129.0>, "Watch a good movie"}
    {#PID<0.125.0>, "Finish the chapter!"}
    :ok
