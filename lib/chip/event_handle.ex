defmodule Circuits.GPIO.Chip.EventHandle do
  @moduledoc false

  ## In Development ##
  alias Circuits.GPIO.Chip.{Line, Nif}

  @type trigger :: :rising | :falling | :both

  def for_line(chip, line_offset, trigger, opts \\ []) do
    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    trigger_byte = trigger_to_byte(trigger)

    Nif.request_lineevent(chip, line_offset, trigger_byte, consumer)
  end

  defp trigger_to_byte(:rising), do: 0x01
  defp trigger_to_byte(:falling), do: 0x02
  defp trigger_to_byte(:both), do: 0x03
end
