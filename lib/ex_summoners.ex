defmodule ExSummoners do
  use Task
  @moduledoc """
  Documentation for `ExSummoners`.
  """

  @api_key "RGAPI-5cc5d334-c745-4288-b635-e2e91aae7f86"
  @regions %{
    "americas" => ~w(na1 br1 la1 la2),
    "asia" => ~w(kr jp1),
    "europe" => ~w(eun1 euw2 tr1 ru),
    "sea" => ~w(oc1 ph2 sg2 th2 tw2 vn2)
  }

  defp grouped_region(region) do
    @regions
    |> Map.filter(fn {_key, val} ->
      Enum.member?(val, region)
    end)
    |> Map.keys()
    |> List.first()
  end

  def recent_participants(name, region) do
    grouped_region = grouped_region(region)
 
    name
    |> get_summoner_by_name(region)
    |> get_matches(grouped_region)
    |> Enum.each(fn match ->
      match
      |> get_match(grouped_region)
      |> monitor_summoners(grouped_region, region)
    end)
  end

  def get_summoner_by_name(name, region) do
    url = "https://#{region}.api.riotgames.com/lol/summoner/v4/summoners/by-name/#{name}?api_key=#{@api_key}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        response["puuid"]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
     end
  end

  def get_summoner_by_puuid(puuid, region) do
    url = "https://#{region}.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/#{puuid}?api_key=#{@api_key}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        response["name"]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
     end
  end

  def get_matches(puuid, region, count \\ 5) do
    url = "https://#{region}.api.riotgames.com/lol/match/v5/matches/by-puuid/#{puuid}/ids?count=#{count}&api_key=#{@api_key}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
     end
  end

  def get_match(match_id, region) do
    url = "https://#{region}.api.riotgames.com/lol/match/v5/matches/#{match_id}?api_key=#{@api_key}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        participant_names =
          response["info"]["participants"]
          |> Enum.map(fn x ->
            x["summonerName"]
          end)

        response["metadata"]["participants"]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
     end
  end

  def monitor_summoners(summoner_puuids, grouped_region, region) do
    for puuid <- summoner_puuids do
      summoner_name = ExSummoners.get_summoner_by_puuid(puuid, region)
      most_recent_match_id = ExSummoners.get_matches(puuid, grouped_region, 1) |> List.first
      new_child_spec = Supervisor.child_spec({ExSummoners.Monitor, {puuid, summoner_name, grouped_region, most_recent_match_id}}, id: puuid)
      Supervisor.start_child(ExSummoners.MonitorSupervisor, new_child_spec)
    end
  end
end
