defmodule Phone.MixProject do
  use Mix.Project

  def project do
    [
      app: :phone,
      version: "0.3.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      xref: [exclude: [Nerves.Runtime]],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger], mod: {Phone.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_uart, "~> 1.4"},
      {:elixircom, "~> 0.2"},
      {:circuits_gpio, "~> 0.4"},
      {:persistent_ets, "~> 0.2.1"},
    ]
  end

  defp aliases() do
    []
  end
end
