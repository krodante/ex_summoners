defmodule ExSummonersTest do
  use ExUnit.Case, async: true
  doctest ExSummoners

  setup do
    bypass = Bypass.open(port: 9999)
    {:ok, bypass: bypass}
  end

  describe "get_summoner_by_name/2" do
    test "calls the Riot api and returns the given summoner's name", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/get_summoner_by_name/200.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 200, json_file)
      end)

      puuid = ExSummoners.get_summoner_by_name("Revenge", "na1")

      assert puuid == puuid()
    end
  end

  describe "get_summoner_by_puuid/2" do
    test "calls the Riot api and returns the given summoner's puuid", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/get_summoner_by_puuid/200.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 200, json_file)
      end)

      name = ExSummoners.get_summoner_by_puuid(puuid(), "na1")

      assert name == "Revenge"
    end
  end

  describe "get_matches/3" do
    test "calls the Riot api and returns the given summoner's most recent matches", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/get_matches/200.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 200, json_file)
      end)

      matches = ExSummoners.get_matches(puuid(), "americas")

      assert matches == matches()
    end
  end

  describe "get_match/2" do
    test "calls the Riot api and returns the participants of a given match ID", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/get_match/200.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 200, json_file)
      end)
      
      participants = ExSummoners.get_match(List.first(matches()), "americas")

      assert participants == participants()
    end
  end

  describe "monitor_summoners/3" do
    test "starts Supervisor children for the given summoner puuids", %{bypass: bypass} do
      start_supervised(ExSummoners.Monitor)

      {:ok, json_file} = File.read("test/support/get_matches/monitor_summoners.json")

      for participant <- participants() do
        puuid = participant[:summoner_puuid]
        response = 
          json_file
          |> Jason.decode!() 
          |> Enum.filter(fn x -> 
            Map.has_key?(x, puuid) 
          end)
          |> List.first()
          |> Map.values()
          |> List.first()
          |> Jason.encode!()

        Bypass.expect(bypass, "GET", "/lol/match/v5/matches/by-puuid/#{puuid}/ids", fn conn ->
          
          Plug.Conn.send_resp(conn, 200, response)
        end)
      end

      ExSummoners.monitor_summoners(participants(), "americas")

      assert Supervisor.which_children(ExSummoners.MonitorSupervisor) |> Enum.count() == 10
    end
  end

  defp puuid do
    "test/support/get_summoner_by_name/200.json"
    |> File.read!() 
    |> Jason.decode!() 
    |> Map.fetch!("puuid")
  end

  defp matches do
    "test/support/get_matches/200.json"
    |> File.read!() 
    |> Jason.decode!()
  end

  defp participants do
    "test/support/get_match/200.json"
    |> File.read!() 
    |> Jason.decode!()
    |> get_in(["info", "participants"])
    |> Enum.map(fn summoner ->
      %{
        summoner_name: summoner["summonerName"],
        summoner_puuid: summoner["puuid"]
      }
    end)
  end
end
