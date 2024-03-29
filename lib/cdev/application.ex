defmodule Circuits.Cdev.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Circuits.Cdev.Events
    ]

    opts = [strategy: :rest_for_one, name: Circuits.Cdev.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
