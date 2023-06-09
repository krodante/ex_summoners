defmodule ExSummoners do
  use Task
  @moduledoc """
  Documentation for `ExSummoners`.
  """

  @api_key "RGAPI-d46c16e2-db35-4a14-93e8-58e3a01171a0"
  @regions %{
    "americas" => ~w(na1 br1 la1 la2),
    "asia" => ~w(kr jp1),
    "europe" => ~w(eun1 euw2 tr1 ru),
    "sea" => ~w(oc1 ph2 sg2 th2 tw2 vn2)
  }

  def thing(name, region) do
    monitored_summoners = recent_participants(name, region)
    grouped_region = 
      @regions
      |> Map.filter(fn {_key, val} -> 
        Enum.member?(val, region)
      end) 
      |> Map.keys() 
      |> List.first()

    monitored_summoners
    |> Task.async_stream(&ExSummoners.track_matches(&1, grouped_region))
    |> Enum.into([], fn {:ok, res} -> res end)
  end

  def track_matches(puuid, region) do
    IO.inspect("in track matches")
    url = "https://#{region}.api.riotgames.com/lol/match/v5/matches/by-puuid/#{puuid}/ids?start=0&count=1&api_key=#{@api_key}"
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

  def recent_participants(name, region) do
    grouped_region = 
      @regions
      |> Map.filter(fn {_key, val} -> 
        Enum.member?(val, region)
      end) 
      |> Map.keys() 
      |> List.first()
    
    name
    |> get_summoner_by_name(region)
    |> get_matches(grouped_region)
    |> List.first()
    |> get_match(grouped_region)
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

  def get_matches(puuid, region) do
    url = "https://#{region}.api.riotgames.com/lol/match/v5/matches/by-puuid/#{puuid}/ids?count=5&api_key=#{@api_key}"

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

        IO.inspect(participant_names)
        response["metadata"]["participants"]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found")
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
     end
  end
end
