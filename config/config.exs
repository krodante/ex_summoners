import Config

config :ex_summoners,
  riot_api_key: System.fetch_env!("RIOT_API_KEY")

import_config "#{config_env()}.exs"
