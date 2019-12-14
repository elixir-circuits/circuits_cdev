defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, Info, LineInfo}

  def open(device_path) do
    device_path
    |> to_charlist()
    |> Nif.open()
  end

  def close(chip) do
    Nif.close(chip)
  end

  def chip_info(chip) do
    Info.get(chip)
  end

  def line_info(chip, line) do
    LineInfo.get(chip, line)
  end

  def request_linehandle(chip, line, requst_flags, opts) do
    consumer = Keyword.get(opts, :consumer, "circuits_cdev")
    default = Keyword.get(opts, :default, 0)

    Nif.request_linehandle(line, requst_flags, default, consumer, chip)
  end
end
