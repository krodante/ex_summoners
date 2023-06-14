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

  def monitor_recent_participants(name, region) do
    grouped_region = grouped_region(region)

    with {:ok, puuid} <- get_summoner_by_name(name, region),
         {:ok, match_ids} <- get_matches(puuid, grouped_region)
    do
      Enum.each(match_ids, fn match_id ->
        case get_match(match_id, grouped_region) do
          {:ok, match_data} -> monitor_summoners(match_data, grouped_region)
          {:error, reason} -> reason
        end           
      end)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def get_summoner_by_name(name, region) do
    response = 
      "/lol/summoner/v4/summoners/by-name/#{name}?api_key=#{@api_key}"
      |> construct_url(region)
      |> HTTPoison.get()
      |> response()
    
    case response do
      {:ok, response} -> {:ok, response["puuid"]}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_matches(puuid, region, count \\ 5) do
    response = 
      "/lol/match/v5/matches/by-puuid/#{puuid}/ids?count=#{count}&api_key=#{@api_key}"
      |> construct_url(region)
      |> HTTPoison.get()
      |> response()
    
    case response do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_match(match_id, region) do
    response = 
      "/lol/match/v5/matches/#{match_id}?api_key=#{@api_key}"
      |> construct_url(region)
      |> HTTPoison.get()
      |> response()

    case response do
      {:ok, response} ->
        summoner_data = 
          response["info"]["participants"]
          |> Enum.map(fn summoner ->
            %{
              summoner_name: summoner["summonerName"],
              summoner_puuid: summoner["puuid"]
            }
          end)
        IO.inspect(Enum.map(summoner_data, fn summoner -> summoner[:summoner_name] end))
        {:ok, summoner_data}
      {:error, reason} -> {:error, reason}
    end

  end

  def monitor_summoners(summoners, grouped_region) do
    for summoner_info <- summoners do
      summoner_name = summoner_info[:summoner_name]
      puuid = summoner_info[:summoner_puuid]

      with {:ok, most_recent_match_id} <- ExSummoners.get_matches(puuid, grouped_region, 1) do
        match_id = List.first(most_recent_match_id)
        new_child_spec = Supervisor.child_spec({ExSummoners.Monitor, {puuid, summoner_name, grouped_region, match_id}}, id: puuid)
        Supervisor.start_child(ExSummoners.MonitorSupervisor, new_child_spec)
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def update_most_recent_match(summoner_data) do
    with {:ok, [match_id]} <- ExSummoners.get_matches(summoner_data.summoner_puuid, summoner_data.region, 1) do
      if match_id == summoner_data.most_recent_match_id do
        {:not_new_match, summoner_data}
      else
        {:new_match, %{summoner_data | most_recent_match_id: match_id}}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp construct_url(endpoint, region) do
    case Mix.env() do
      :dev -> "https://#{region}.api.riotgames.com" <> endpoint
      :test -> "http://localhost:9999" <> endpoint
    end
  end

  defp grouped_region(region) do
    @regions
    |> Map.filter(fn {_key, val} ->
      Enum.member?(val, region)
    end)
    |> Map.keys()
    |> List.first()
  end

  defp response({:ok, %{status_code: 200, body: body}}), do: {:ok, Jason.decode!(body)}
  defp response({:ok, %{status_code: status_code, body: body}}) do
    message = 
      body
      |> Jason.decode!()
      |> get_in(["status", "message"])
    {:error, "HTTP Status #{status_code}: #{message}"}
  end
  defp response({:error, %{reason: reason}}), do: {:error, reason}
end
 