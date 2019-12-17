defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, Info, LineInfo}

  @type t :: reference()

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

  def line_info(chip, line) do
    LineInfo.get(chip, line)
  end

  def request_linehandle(chip, line, requst_flags, opts) do
    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    default = Keyword.get(opts, :default, 0)

    Nif.request_linehandle(chip, line, default, requst_flags, consumer)
  end

  def set_value(handle, value) do
    Nif.set_value(handle, value)
  end

  def get_value(hanlde) do
    Nif.get_value(hanlde)
  end
end
