defmodule ClusterBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :cluster_bot,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "ClusterBot",
      source_url: "https://github.com/micartey/cluster-bot",
      docs: [
        main: "readme.html",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cachex, "~> 4.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    ]
  end

  defp description() do
    "Automatically keep track of connected nodes to store and reconnect with them"
  end

  defp package() do
    [
      name: "cluster_bot",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/micartey/cluster-bot"}
    ]
  end
end
