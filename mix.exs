defmodule Gramex.MixProject do
  use Mix.Project

  @version "0.0.4"
  @source_url "https://github.com/mxgrn/gramex"

  def project do
    [
      app: :gramex,
      version: @version,
      elixir: "~> 1.18",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.0"},
      {:req, "~> 0.5"},

      # because we need Phoenix.ConnTest, although at some point Plug.Conn might suffice
      {:phoenix, "~> 1.0"},
      {:nimble_options, "~> 1.0"},
      {:quokka, "~> 2.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mimic, "~> 1.12", only: :test}
    ]
  end

  defp package do
    [
      description: "Very basic and feature-incomplete Telegram bot API helpers",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end
end
