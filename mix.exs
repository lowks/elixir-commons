defmodule Commons.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_commons,
     version: "0.0.1",
     elixir: "~> 0.14.3",
     deps: deps]
  end

  def  application, do: [applications: []]
  defp deps,        do: []
end
