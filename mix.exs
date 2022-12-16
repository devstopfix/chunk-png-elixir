defmodule ChunkPNG.MixProject do
  use Mix.Project

  def project do
    [
      app: :chunk_png,
      deps: deps(),
      description: "Manipulate metadata of PNGs",
      elixir: "~> 1.10",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: "1.0.348"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:codepagex, "~> 0.1.6"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"src" => "https://github.com/devstopfix/chunk-png-elixir"}
    ]
  end
end
