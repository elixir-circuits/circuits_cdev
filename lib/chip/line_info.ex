defmodule Circuits.GPIO.Chip.LineInfo do
  alias Circuits.GPIO.Chip.Nif

  defstruct line: nil, name: nil, consumer: nil, flags: nil

  def get(chip, line) do
    {flags, name, consumer} = Nif.get_line_info(chip, line)

    %__MODULE__{
      line: line,
      name: charlist_to_string_or_nil(name),
      consumer: charlist_to_string_or_nil(consumer),
      flags: flags
    }
  end

  defp charlist_to_string_or_nil([]), do: nil
  defp charlist_to_string_or_nil(charlist), do: to_string(charlist)
end
