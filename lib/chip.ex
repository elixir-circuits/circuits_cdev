defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, Info, Line, LineHandleMulti}

  @opaque t :: reference()

  @spec open(String.t()) :: {:ok, t()}
  def open(device_path) do
    device_path
    |> to_charlist()
    |> Nif.open()
  end

  @spec close(t()) :: :ok
  def close(chip) do
    Nif.close(chip)
  end

  @spec chip_info(t()) :: {:ok, Info.t()}
  def chip_info(chip) do
    Info.get(chip)
  end

  @spec get_line(t(), Line.offset()) :: Line.t()
  def get_line(chip, offset), do: Line.new(chip, offset)

  @spec get_lines(t(), [Line.offset()]) :: [Line.t()]
  def get_lines(chip, offsets), do: Enum.map(offsets, fn offset -> Line.new(chip, offset) end)

  def request_linehandle(chip, offset, direction, opts \\ []) do
    chip
    |> Line.new(offset)
    |> Line.request_handle(direction, opts)
  end

  def request_linehandle_multi(chip, lines, direction, opts \\ []) do
    chip
    |> get_lines(lines)
    |> LineHandleMulti.for_lines(direction, opts)
  end
end
