defmodule Circuits.GPIO.Chip.Line do
  alias Circuits.GPIO.Chip
  alias Circuits.GPIO.Chip.Nif

  @type offset :: non_neg_integer()

  @type t :: %__MODULE__{
          chip: Chip.t(),
          offset: offset(),
          name: String.t(),
          consumer: String.t(),
          hanlde: reference() | nil,
          # this will change
          flags: integer()
        }

  defstruct chip: nil, offset: nil

  @spec new(Chip.t(), offset()) :: t()
  def new(chip, offset) do
    {flags, name, consumer} = Nif.get_line_info(chip.ref, offset)

    %__MODULE__{
      chip: chip,
      offset: offset,
      name: charlist_to_string_or_nil(name),
      consumer: charlist_to_string_or_nil(consumer),
      flags: flags
    }
  end

  defp charlist_to_string_or_nil([]), do: nil
  defp charlist_to_string_or_nil(charlist), do: to_string(charlist)
end
