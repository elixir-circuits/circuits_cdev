defmodule Circuits.GPIO.Chip.Info do
  alias Circuits.GPIO.Chip
  alias Circuits.GPIO.Chip.Nif

  @type t :: %__MODULE__{
          name: String.t(),
          label: String.t(),
          number_of_lines: non_neg_integer()
        }

  defstruct name: nil, label: nil, number_of_lines: 0

  @spec get(Chip.t()) :: {:ok, t()}
  def get(chip) do
    {name, label, lines} = Nif.get_info(chip)
    {:ok, %__MODULE__{name: to_charlist(name), label: to_charlist(label), number_of_lines: lines}}
  end
end
