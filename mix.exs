defmodule Commons.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_commons,
     version: "0.0.2",
     elixir: "~> 0.15.1",
     deps: deps]
  end

  def  application, do: [applications: []]
  defp deps,        do: []
end
