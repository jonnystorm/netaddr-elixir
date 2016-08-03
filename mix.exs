defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [ app: :netaddr_ex,
      version: "0.0.12",
      name: "NetAddr",
      source_url: "https://github.com/jonnystorm/netaddr-elixir",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      docs: [extras: ["README.md"]]
    ]
  end

  def application do
    [ applications: [
        :logger,
        :jds_math_ex,
        :linear_ex
      ]
    ]
  end

  defp deps do
    [ {:jds_math_ex, git: "https://github.com/jonnystorm/jds-math-elixir"},
      {:linear_ex, git: "https://github.com/jonnystorm/linear-elixir"},
      {:ex_doc, git: "https://github.com/elixir-lang/ex_doc", ref: "d5618937670708359437729d253ab56f4933bc9c", only: :dev}
    ]
  end
end
