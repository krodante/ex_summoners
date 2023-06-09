defmodule ExSummoners.Supervisor do
  use GenServer

  def start_link(init_arg) do
    # Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    IO.inspect("starting", label: "ExSummoners.Supervisor")
    GenServer.start_link(__MODULE__, init_arg)
    # IO.inspect("started", label: "ExSummoners.Supervisor")
  end

  def do_thing(pid) do
    GenServer.call(pid, :do_thing)
  end

  @impl true
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    schedule_work()
    {:noreply, state}
  end

  def handle_call({:thing, name, region}, _from, state) do
    result = ExSummoners.thing(name, region)
    {:reply, result, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 3000)
  end
end
