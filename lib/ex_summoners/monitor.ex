defmodule ExSummoners.Monitor do
  use GenServer

  @interval 60000

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def init({summoner_puuid, summoner_name, region, most_recent_match_id}) do
    status = %{
      summoner_puuid: summoner_puuid,
      summoner_name: summoner_name,
      region: region,
      most_recent_match_id: most_recent_match_id,
      timer: :erlang.start_timer(@interval, self(), :tick)
    }

    {:ok, status}
  end

  def handle_call(:get, _from, status) do
    IO.inspect("Monitor handle_call")
    {:reply, status.current, status}
  end

  def handle_info({:timeout, _timer_ref, :tick}, status) do
    IO.inspect("Monitor handle tick for #{status.summoner_puuid}")
    new_timer = :erlang.start_timer(@interval, self(), :tick)
    :erlang.cancel_timer(status.timer)

    match_id = ExSummoners.get_matches(status.summoner_puuid, status.region, 1) |> List.first()

    if match_id == status.most_recent_match_id do
      {:noreply, %{status | timer: new_timer}}
    else
      IO.inspect("Summoner #{status.summoner_name} has completed match #{status.most_recent_match_id}")
      {:noreply, %{status | most_recent_match_id: match_id, timer: new_timer}}
    end
  end
end
