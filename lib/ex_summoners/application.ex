defmodule ExSummoners.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ExSummoners.MonitorSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: ExSummoners.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
