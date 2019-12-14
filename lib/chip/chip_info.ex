defmodule Circuits.GPIO.Chip.Info do
  alias Circuits.GPIO.Chip.Nif

  defstruct name: nil, label: nil, number_of_lines: 0

  def get(chip) do
    {name, label, lines} = Nif.get_info(chip)
    {:ok, %__MODULE__{name: to_charlist(name), label: to_charlist(label), number_of_lines: lines}}
  end
end
