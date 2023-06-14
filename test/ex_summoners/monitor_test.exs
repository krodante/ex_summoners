defmodule ExSummoners.MonitorTest do
  use ExUnit.Case
  alias ExSummoners.Monitor
  doctest Monitor

  @valid_init [{"fake_puuid", "fake_name", "region", "most_recent_match_id"}]

  test "init/1" do
    child_spec = %{
      id: "fake_puuid",
      start: {Monitor, :start_link, @valid_init}
    }
    
    pid = start_supervised!(child_spec)

    assert Monitor.get(pid)[:summoner_puuid] == "fake_puuid"
  end

  test "handle_info/2 :: :timeout" do
    bypass = Bypass.open(port: 9999)

    Bypass.expect(bypass, "GET", "/lol/match/v5/matches/by-puuid/fake_puuid/ids", fn conn ->
      assert "1" == conn.params["count"]
      Plug.Conn.send_resp(conn, 200, Jason.encode!(["newest_match"]))
    end)

    {:noreply, response, timer} = Monitor.handle_info({:timeout, "", :tick}, %{
      summoner_puuid: "fake_puuid",
      summoner_name: "fake_name",
      region: "region",
      most_recent_match_id: "most_recent_match_id",
      timer: :erlang.start_timer(1000, self(), :tick)
    })

    assert response[:most_recent_match_id] == "newest_match"
  end
end