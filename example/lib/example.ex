defmodule Example do
  @moduledoc false

  use GenServer

  alias Circuits.GPIO.Chip

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    chip = Keyword.get(args, :chip, "gpiochip0")
    led1 = Keyword.get(args, :led1, 17)
    led2 = Keyword.get(args, :led2, 22)
    button = Keyword.get(args, :button, 27)

    {:ok, line} = Chip.request_lines(chip, [led1, led2], :output)

    # Set initial values led1 will be on and led2 will be off
    :ok = Chip.set_values(line, [1, 0])

    :ok = Chip.listen_event("gpiochip0", button)

    {:ok, line}
  end

  @impl GenServer
  def handle_info({:circuits_cdev, 27, _timestamp, 1}, line) do
    Chip.set_values(line, [0, 1])

    {:noreply, line}
  end

  def handle_info({:circuits_cdev, 27, _timestamp, 0}, line) do
    Chip.set_values(line, [1, 0])

    {:noreply, line}
  end
end
