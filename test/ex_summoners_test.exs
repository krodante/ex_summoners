defmodule ExSummonersTest do
  use ExUnit.Case, async: true
  doctest ExSummoners

  setup do
    bypass = Bypass.open(port: 9999)
    {:ok, bypass: bypass}
  end

  describe "get_summoner_by_name/2" do
    test "calls the Riot api and returns the given summoner's name", %{bypass: bypass} do
      stub_get_summoner_by_name(bypass)

      {:ok, puuid} = ExSummoners.get_summoner_by_name("fake_name", "na1")

      assert puuid == puuid()
    end
  end

  describe "get_matches/3" do
    test "calls the Riot api and returns the given summoner's most recent matches", %{bypass: bypass} do
      stub_get_matches(bypass)

      {:ok, matches} = ExSummoners.get_matches("fake_puuid", "americas")

      assert matches == matches()
    end
  end

  describe "get_match/2" do
    test "calls the Riot api and returns the participants of a given match ID", %{bypass: bypass} do
      stub_get_match(bypass)
      
      {:ok, participants} = ExSummoners.get_match(List.first(matches()), "americas")

      assert participants == participants()
    end
  end

  describe "monitor_summoners/3" do
    test "starts Supervisor children for the given summoner puuids", %{bypass: bypass} do
      start_supervised(ExSummoners.Monitor)

      stub_multiple_get_matches_calls(bypass)

      ExSummoners.monitor_summoners(participants(), "americas")

      assert Supervisor.which_children(ExSummoners.MonitorSupervisor) |> Enum.count() == 10
    end
  end

  describe "monitor_recent_participants/2" do
    test "starts Supervisor children for the given summoner puuids", %{bypass: bypass} do
      start_supervised(ExSummoners.Monitor)

      stub_get_summoner_by_name(bypass)
      stub_get_matches(bypass)
      stub_get_match(bypass)
      stub_multiple_get_matches_calls(bypass)

      ExSummoners.monitor_recent_participants("fake_name", "na1")

      assert Supervisor.which_children(ExSummoners.MonitorSupervisor) |> Enum.count() == 10
    end

    test "handles api errors gracefully" do
      
    end
  end

  describe "Riot API errors" do
    test "handles 400 errors", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/error_responses/400.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 400, json_file)
      end)
      
      {:error, response} = ExSummoners.get_summoner_by_name("wonky", "na1")

      assert response == "HTTP Status 400: Bad Request - Exception decrypting wonky"
    end

    test "handles 401 errors", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/error_responses/401.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 401, json_file)
      end)
      
      {:error, response} = ExSummoners.get_summoner_by_name("valid_name", "na1")

      assert response == "HTTP Status 401: Unauthorized"
    end

    test "handles 404 errors", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/error_responses/404.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 404, json_file)
      end)
      
      {:error, response} = ExSummoners.get_summoner_by_name("eu_name", "na1")

      assert response == "HTTP Status 404: Data not found - summoner not found" 
    end

    test "handles 429 errors", %{bypass: bypass} do
      {:ok, json_file} = File.read("test/support/error_responses/429.json")
      
      Bypass.expect(bypass, fn conn ->
        assert "GET" == conn.method
        Plug.Conn.send_resp(conn, 429, json_file)
      end)
      
      {:error, response} = ExSummoners.get_summoner_by_name("valid_name", "na1")

      assert response == "HTTP Status 429: Rate limit exceeded"
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

  defp stub_get_summoner_by_name(bypass) do
    {:ok, json_file} = File.read("test/support/get_summoner_by_name/200.json")
      
    Bypass.expect(bypass, "GET", "/lol/summoner/v4/summoners/by-name/fake_name", fn conn ->
      Plug.Conn.send_resp(conn, 200, json_file)
    end)
  end

  defp stub_get_matches(bypass) do
    {:ok, json_file} = File.read("test/support/get_matches/200.json")

    Bypass.expect(bypass, "GET", "/lol/match/v5/matches/by-puuid/fake_puuid/ids", fn conn ->
      assert "5" == conn.params["count"]
      Plug.Conn.send_resp(conn, 200, json_file)
    end)
  end

  defp stub_get_match(bypass) do
    {:ok, json_file} = File.read("test/support/get_match/200.json")
      
    Bypass.expect(bypass, fn conn ->
      assert String.contains?(conn.request_path, "/lol/match/v5/matches/NA")
      Plug.Conn.send_resp(conn, 200, json_file)
    end)
  end

  defp stub_multiple_get_matches_calls(bypass) do
    {:ok, json_file} = File.read("test/support/get_matches/monitor_summoners.json")

    for participant <- participants() do
        puuid = participant[:summoner_puuid]
        response = 
          json_file
          |> Jason.decode!()
          |> Map.fetch!(puuid)
          |> Jason.encode!()

        Bypass.expect(bypass, "GET", "/lol/match/v5/matches/by-puuid/#{puuid}/ids", fn conn ->
          assert "1" = conn.params["count"]
          Plug.Conn.send_resp(conn, 200, response)
        end)
      end
  end
end
