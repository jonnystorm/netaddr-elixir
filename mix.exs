defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [ app: :netaddr_ex,
      version: "1.0.0",
      name: "NetAddr",
      source_url: "https://github.com/jonnystorm/netaddr-elixir",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]],
      dialyzer: [
        ignore_warnings: "dialyzer.ignore",
        flags: [
          :unmatched_returns,
          :error_handling,
          :race_conditions,
          :underspecs,
        ],
      ],
    ]
  end

  def application do
    [ applications: [
        :logger,
        :jds_math_ex,
        :linear_ex,
      ]
    ]
  end

  defp deps do
    [ {:jds_math_ex, git: "https://github.com/jonnystorm/jds-math-elixir"},
      {:linear_ex, git: "https://github.com/jonnystorm/linear-elixir"},
      {:ex_doc, git: "https://github.com/elixir-lang/ex_doc"},
    ]
  end
end
