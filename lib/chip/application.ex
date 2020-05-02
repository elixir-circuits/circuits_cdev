defmodule Circuits.GPIO.Chip.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Circuits.GPIO.Chip.InterruptServer
    ]

    opts = [strategy: :rest_for_one, name: Circuits.GPIO.Chip.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
