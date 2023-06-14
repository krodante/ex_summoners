defmodule ExSummoners.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_summoners,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExSummoners.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:httpoison, "~> 2.0"},
      {:bypass, "~> 2.1", only: :test}
    ]
  end
end
