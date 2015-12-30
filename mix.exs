defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [app: :netaddr_ex,
     version: "0.0.2",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:jds_math_ex, git: "https://github.com/jonnystorm/jds-math-elixir"},
      {:linear_ex, git: "https://github.com/jonnystorm/linear-elixir"}
    ]
  end
end
