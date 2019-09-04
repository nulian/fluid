defmodule Liquid.Mixfile do
  use Mix.Project

  def project do
    [
      app: :liquid,
      version: "0.9.1",
      elixir: "~> 1.5",
      deps: deps(),
      name: "Liquid",
      description: description(),
      package: package(),
      source_url: "https://github.com/bettyblocks/liquid-elixir",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application
  def application do
    [mod: {Liquid, []}]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      {:credo, "~> 0.9.0 or ~> 1.0", only: [:dev, :test]},
      {:benchee, "~> 0.11", only: :dev},
      {:benchfella, "~> 0.3", only: [:dev, :test]},
      {:timex, "~> 3.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:blankable, "~> 1.0.0"}
    ]
  end

  defp description do
    """
    Liquid implementation in elixir
    """
  end

  defp package do
    [
      files: ["lib", "README*", "mix.exs"],
      maintainers: ["Peter Arentsen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nulian/liquid-elixir"}
    ]
  end
end
