defmodule ExSummoners.Monitor do
  use GenServer

  @interval :timer.seconds(10) # 1 minute

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def init({summoner_puuid, summoner_name, region, most_recent_match_id}) do
    state = %{
      summoner_puuid: summoner_puuid,
      summoner_name: summoner_name,
      region: region,
      most_recent_match_id: most_recent_match_id,
      timer: :erlang.start_timer(@interval, self(), :tick)
    }

    {:ok, state, :timer.hours(1)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:timeout, _, :tick}, state) do
    new_timer = :erlang.start_timer(@interval, self(), :tick)
    :erlang.cancel_timer(state.timer)

    case ExSummoners.update_most_recent_match(%{state | timer: new_timer}) do
      {:new_match, new_state} -> 
        IO.inspect("Summoner #{new_state.summoner_name} has completed match #{state.most_recent_match_id}")
        {:noreply, new_state, @interval}
      {:not_new_match, state} -> {:noreply, state, @interval}
      {:error, reason} -> {:error, reason}
    end
  end
end
