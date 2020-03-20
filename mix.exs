defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [ app: :netaddr_ex,
      version: "1.2.0",
      name: "NetAddr",
      source_url: "https://gitlab.com/jonnystorm/netaddr-elixir.git",
      description: description(),
      package: package(),
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
      ]
    ]
  end

  defp deps do
    [ {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:cmark, "~> 0.6", only: :dev},
    ]
  end

  defp description do
    "General functions for network address parsing and manipulation, with support for addresses of arbitrary size."
  end

  defp package do
    [ licenses: ["Mozilla Public License 2.0"],
      links: %{
        "GitLab" => "https://gitlab.com/jonnystorm/netaddr-elixir",
        "GitHub" => "https://github.com/jonnystorm/netaddr-elixir",
      },
    ]
  end
end
