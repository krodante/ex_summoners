defmodule ExSummoners do
  use Task
  @moduledoc """
  Documentation for `ExSummoners`.
  """

  @api_key Application.compile_env(:ex_summoners, :riot_api_key)
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
      |> monitor_summoners(grouped_region)
    end)
  end

  def get_summoner_by_name(name, region) do
    endpoint = "/lol/summoner/v4/summoners/by-name/#{name}?api_key=#{@api_key}"
    url = construct_url(endpoint, region)

    response = 
      url
      |> HTTPoison.get()
      |> response()
    
    case response do
      {:ok, response} -> response["puuid"]
      {:error, reason} -> reason
    end
  end

  def get_summoner_by_puuid(puuid, region) do
    endpoint = "/lol/summoner/v4/summoners/by-puuid/#{puuid}?api_key=#{@api_key}"
    url = construct_url(endpoint, region)

    response = 
      url
      |> HTTPoison.get()
      |> response()

    case response do
      {:ok, response} -> response["name"]
      {:error, reason} -> reason
    end
  end

  def get_matches(puuid, region, count \\ 5) do
    endpoint = "/lol/match/v5/matches/by-puuid/#{puuid}/ids?count=#{count}&api_key=#{@api_key}"
    url = construct_url(endpoint, region)

    response = 
      url
      |> HTTPoison.get()
      |> response()
    
    case response do
      {:ok, response} -> response
      {:error, reason} -> reason
    end
  end

  def get_match(match_id, region) do
    endpoint = "/lol/match/v5/matches/#{match_id}?api_key=#{@api_key}"
    url = construct_url(endpoint, region)

    response = 
      url
      |> HTTPoison.get()
      |> response()

    case response do
      {:ok, response} ->
        response["info"]["participants"]
        |> Enum.map(fn summoner ->
          %{
            summoner_name: summoner["summonerName"],
            summoner_puuid: summoner["puuid"]
          }
        end)
      {:error, reason} -> reason
    end

  end

  def monitor_summoners(summoners, grouped_region) do
    for summoner_info <- summoners do
      summoner_name = summoner_info[:summoner_name]
      puuid = summoner_info[:summoner_puuid]
      most_recent_match_id = ExSummoners.get_matches(puuid, grouped_region, 1) |> List.first
      new_child_spec = Supervisor.child_spec({ExSummoners.Monitor, {puuid, summoner_name, grouped_region, most_recent_match_id}}, id: puuid)
      Supervisor.start_child(ExSummoners.MonitorSupervisor, new_child_spec)
    end
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, Jason.decode!(body)}
  defp response({:ok, %{status_code: status_code}}), do: {:error, "HTTP Status #{status_code}"}
  defp response({:error, %{reason: reason}}), do: {:error, reason}

  defp construct_url(endpoint, region \\ "") do
    case Mix.env() do
      :dev -> "https://#{region}.api.riotgames.com" <> endpoint
      :test -> "http://localhost:9999" <> endpoint
    end
  end
end
