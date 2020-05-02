defmodule CircuitsCdev.MixProject do
  use Mix.Project

  def project do
    [
      app: :circuits_cdev,
      version: "0.1.0",
      elixir: "~> 1.9",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Circuits.GPIO.Chip.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.21.3", only: :docs, runtime: false}
    ]
  end
end
