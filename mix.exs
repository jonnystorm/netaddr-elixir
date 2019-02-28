defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [ app: :netaddr_ex,
      version: "1.0.4",
      name: "NetAddr",
      source_url: "https://gitlab.com/jonnystorm/netaddr-elixir",
      elixir: "~> 1.7",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        main: "NetAddr",
        extras: ~w(README.md),
        markdown_processor: ExDoc.Markdown.Cmark,
      ],
      dialyzer: [
        add_plt_apps: [
          :logger,
          :jds_math_ex,
          :linear_ex,
        ],
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
    [ { :jds_math_ex,
        git: "https://gitlab.com/jonnystorm/jds-math-elixir.git"
      },
      { :linear_ex,
        git: "https://gitlab.com/jonnystorm/linear-elixir.git"
      },
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:cmark, "~> 0.6", only: :dev},
    ]
  end
end
