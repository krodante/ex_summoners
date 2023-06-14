defmodule ExSummoners.MonitorSupervisor do
  use Supervisor

  def start_link(summoner_puuids) do
    IO.inspect("starting", label: "ExSummoners.MonitorSupervisor")
    Supervisor.start_link(__MODULE__, summoner_puuids, name: __MODULE__)
  end

  @impl true
  def init(summoner_puuids) do
    children = 
      for summoner_puuid <- summoner_puuids do
        Supervisor.child_spec({ExSummoners.Monitor, summoner_puuid}, id: summoner_puuid)
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
