defmodule Normative.MixProject do
  use Mix.Project

  def project do
    [
      app: :normative,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: Mix.env() |> elixirc_paths(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:norm, "~> 0.12.0"},
      {:ex_doc, "~> 0.21.3", only: [:dev]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib/", "test/support/"]
  defp elixirc_paths(_), do: ["lib/"]
end
