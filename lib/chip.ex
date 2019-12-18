defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, Info, Line, LineHandle}

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

  @spec request_linehandle(t(), Line.offest(), LineHandle.direction(), keywork()) ::
          LineHandle.t()
  def request_linehandle(chip, offset, direction, opts \\ []) do
    chip
    |> Line.new(offset)
    |> Line.request_linehandle(direction, opts)
  end
end
