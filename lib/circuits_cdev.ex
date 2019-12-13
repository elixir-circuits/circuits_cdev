defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, Line}

  @type t :: %__MODULE__{
          ref: reference(),
          name: String.t(),
          consumer: String.t(),
    number_of_lines: non_neg_integer(),
    label: Strin.t()
        }

  defstruct ref: nil, name: nil, consumer: nil, number_of_lines: 0, label: nil

  @spec open(String.t()) :: {:ok, t()}
  def open(chip_device) do
    case Nif.open(to_charlist(chip_device)) do
      {:ok, chip_ref} ->
        {name, label, lines} = Nif.get_info(chip_ref)

        {:ok,
         %__MODULE__{
           ref: chip_ref,
           name: to_charlist(name),
           label: to_charlist(label),
           number_of_lines: lines
         }}
    end
  end

  @spec close(t()) :: :ok
  def close(%__MODULE__{ref: ref}), do: Nif.close(ref)

  @spec get_line(t(), Line.offset()) :: Line.t()
  def get_line(chip, offset) do
    Line.new(chip, offset)
  end
end
