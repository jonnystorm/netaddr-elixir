defmodule NetAddr.Mixfile do
  use Mix.Project

  def project do
    [ app: :netaddr_ex,
      version: "1.3.2",
      name: "NetAddr",
      source_url: "https://gitlab.com/jonnystorm/netaddr-elixir.git",
      description: description(),
      package: package(),
      elixir: "~> 1.12",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        main: "NetAddr",
        extras: ~w(README.md),
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
      [extra_applications: [:logger]]
  end

  defp deps do
    [
      #{:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:ex_doc, "~> 0.34"}
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
