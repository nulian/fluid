defmodule Liquid.Mixfile do
  use Mix.Project

  def project do
    [ app: :liquid,
      version: "0.8.0",
      elixir: "~> 1.3",
      deps: deps(),
      name: "Liquid",
      description: description(),
      package: package(),
      source_url: "https://github.com/bettyblocks/liquid-elixir"]
  end

  # Configuration for the OTP application
  def application do
    [mod: {Liquid, []}]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:credo, "~> 0.2", only: [:dev, :test]},
     {:benchfella, "~> 0.3.0", only: [:dev, :test]},
     {:timex, "~> 3.0"},
     {:ex_doc, ">= 0.0.0", only: :dev},
      {:exprof, "~> 0.2.0"} ]
  end

  defp description do
    """
    Liquid implementation in elixir
    """
  end

  defp package do
    [
      files: ["lib", "README*", "mix.exs", "src"],
      maintainers: ["Peter Arentsen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nulian/liquid-elixir"}
    ]
  end
end
