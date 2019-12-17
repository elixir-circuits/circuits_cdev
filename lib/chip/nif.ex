defmodule Circuits.GPIO.Chip.Nif do
  @on_load {:load_nif, 0}
  @compile {:autoload, false}

  def load_nif() do
    nif_binary = Application.app_dir(:circuits_cdev, "priv/cdev_nif")

    :erlang.load_nif(to_charlist(nif_binary), 0)
  end

  def open(_chip_device) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def close(_chip) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def get_info(_chip_ref) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def get_line_info(_chip, _line_offset) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def request_linehandle(_chip, _lineoffset, _default_value, _flag, _consumer) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def set_value(_handle, _value) do
    :erlang.nif_error(:nif_not_loaded)
  end

  def get_value(_handle) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
