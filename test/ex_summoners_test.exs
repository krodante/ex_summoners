defmodule ExSummonersTest do
  use ExUnit.Case
  doctest ExSummoners

  describe "get_summoner_by_name/2" do
    test "call the Riot api and returns the given summoner's puuid" do
      puuid = ExSummoners.get_summoner_by_name("Matt", "na1")

      assert puuid == "o4aD61XQ3h9KLWgfsdYv8ekeAMEiNWjF55nDkQ4nWk3p_5b9nRpZds5rSWV8Ag37RD8CL0SvIr0Eng"
    end
  end

  describe "get_summoner_by_puuid/2" do
    test "call the Riot api and returns the given summoner's puuid" do
      name = ExSummoners.get_summoner_by_puuid("o4aD61XQ3h9KLWgfsdYv8ekeAMEiNWjF55nDkQ4nWk3p_5b9nRpZds5rSWV8Ag37RD8CL0SvIr0Eng", "na1")

      assert name == "Matt"
    end
  end
end
