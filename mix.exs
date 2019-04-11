defmodule PagerDutyReport.MixProject do
  use Mix.Project

  def project do
    [
      app: :pager_duty_report,
      version: "1.0.0",
      elixir: "~> 1.7",
      escript: [main_module: PagerDutyReport.CLI],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :yaml_elixir],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :envy, "~> 1.1.1" },
      { :httpoison, "~> 1.5" },
      { :progress_bar, "> 0.0.0" },
      { :poison, "~> 3.1" },
      { :timex, "~> 3.1" },
      { :tzdata, "~> 0.1.8", override: true },
      { :yaml_elixir, "~> 2.2" }
    ]
  end
end
