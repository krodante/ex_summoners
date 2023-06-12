defmodule ExSummonersTest do
  use ExUnit.Case
  doctest ExSummoners

  @puuid "o4aD61XQ3h9KLWgfsdYv8ekeAMEiNWjF55nDkQ4nWk3p_5b9nRpZds5rSWV8Ag37RD8CL0SvIr0Eng"
  @matches ["NA1_4419718970", "NA1_4419672143", "NA1_4404762522", "NA1_4404707710", "NA1_4402832397"]
  @participants [
              "hw-Dd5FseltZ7igJ8ZzFtieoTe7KowfhpvTlxW_tCUSLmgj_u6wKdKNaKdq2WP-WH0c4U0SBRsXnug",
              "3IUFk0NALRJA2h4zvkm3mL8OWrWJpqefqifFr7W52ysYrnQDtHE30oAuFOIIa1Qqg8UxtdnxBipXvw",
              "ji7bKOftvPkQqTrQ5yAIwrcvFnuHa-Xrw_SmjzvvGNsY2o8kpBi8YAgU-ALvMtD-ATTQTqzQqBoxrA",
              "r6lxTzb14YmPZ1dXpiOrTDenIYvg1jh7Cb5aCbfx07ODLdjRl3xdSGUM9bmOMMCA7n8tHwFInqytJA",
              "o4aD61XQ3h9KLWgfsdYv8ekeAMEiNWjF55nDkQ4nWk3p_5b9nRpZds5rSWV8Ag37RD8CL0SvIr0Eng",
              "eWA8fkJyd-COMiaWRfWryuDf3pQoTz-5cSa7QhO2H9CiAbSsusdrcFB-Ly2UFruZRncfuLclQWAr6Q",
              "2MvFbfjd7bnMbKAjVGFGvWo5mvgLUnZH2GVdPVQPj2_xOVlhM_Af8k8l40aVys29kbuwzMKkKrtHDg",
              "MlGTjt3Kl89qkibZL0eFPVybOPP4Av8yur1BnkUBJQGL4HK3mOryWs3BkW8rmGd6x6_-rBoa1Yh0aQ",
              "ytkZfQry2S96ah0EVOpfWLtrlilpwEZpMPNtwjrSRWWvpPY8QSo7nFftOuyOy4O4fpeREhgNjCZ3Zw",
              "l5cym_aROZrZYWtcx8OqonozsNoPP-hBmIyehJDjpvNliPHPAJsLAQfk6EUTao5bO7k4hhMFbUO1iA"
            ]

  describe "get_summoner_by_name/2" do
    test "calls the Riot api and returns the given summoner's name" do
      puuid = ExSummoners.get_summoner_by_name("Matt", "na1")

      assert puuid == @puuid
    end
  end

  describe "get_summoner_by_puuid/2" do
    test "calls the Riot api and returns the given summoner's puuid" do
      name = ExSummoners.get_summoner_by_puuid(@puuid, "na1")

      assert name == "Matt"
    end
  end

  describe "get_matches/3" do
    test "calls the Riot api and returns the given summoner's most recent matches" do
      matches = ExSummoners.get_matches(@puuid, "americas")

      assert matches == @matches
    end
  end

  describe "get_match/2" do
    test "calls the Riot api and returns the participants of a given match ID" do
      participants = ExSummoners.get_match(List.first(@matches), "americas")

      assert participants == @participants
    end
  end

  describe "monitor_summoners/3" do
    test "starts Supervisor children for the given summoner puuids" do
      start_supervised(ExSummoners.Monitor)

      ExSummoners.monitor_summoners(@participants, "americas", "na1")

      assert Supervisor.which_children(ExSummoners.MonitorSupervisor) |> Enum.count() == 10
    end
  end
end
