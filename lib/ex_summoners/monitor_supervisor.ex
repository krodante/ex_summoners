defmodule ExSummoners.MonitorSupervisor do
  use Supervisor

  def start_link(summoner_puuids) do
    IO.inspect("starting", label: "ExSummoners.MonitorSupervisor")
    Supervisor.start_link(__MODULE__, summoner_puuids, name: __MODULE__)
  end

  @impl true
  def init(summoner_puuids) do
    IO.inspect("MonitorSummoner init")
    children = 
      for summoner_puuid <- summoner_puuids do
        Supervisor.child_spec({ExSummoners.Monitor, summoner_puuid}, id: summoner_puuid)
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  # @impl true
  # def handle_info(:work, state) do
  #   schedule_work()
  #   {:noreply, state}
  # end

  # @impl true
  # def handle_call({:track_matches, name, region}, _from, state) do
  #   IO.inspect("in handle call")
  #   result = ExSummoners.thing(name, region)
  #   {:reply, result, state}
  # end

  # defp schedule_work() do
  #   Process.send_after(self(), :work, 3000)
  # end
end
