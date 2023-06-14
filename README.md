# ExSummoners

### Setup
* This project assumes you already have elixir and erlang installed on your machine.
* Set your `RIOT_API_KEY` environment variable in the terminal:
	```
	export RIOT_API_KEY=your_api_key
	```
* Navigate to the project directory
* Install dependencies with `mix deps.get`
* Run tests with `mix test`
* Start the console with `iex -S mix`
* Start the monitor with `ExSummoners.monitor_recent_participants("summoner_name", "summoner_region")`
