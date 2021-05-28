defmodule Chexx.MixProject do
  use Mix.Project

  def project do
    [
      app: :chexx,
      version: "0.1.0",
      elixir: "~> 1.11",
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
      {:exprof, "~> 0.2.0"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ok, "~> 2.3"},
      {:stream_data, "~> 0.5", only: :test}
    ]
  end
end
