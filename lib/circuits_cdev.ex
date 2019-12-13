defmodule Circuits.GPIO.Chip do
  defmodule Nif do
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
  end

  @spec open(String.t()) :: {:ok, reference()}
  def open(chip_device) do
    chip_device
    |> to_charlist()
    |> Nif.open()
  end

  @spec close(reference()) :: :ok
  def close(chip), do: Nif.close(chip)

  @spec get_info(reference()) :: %{name: String.t(), label: String.t(), lines: integer()}
  def get_info(chip) do
    {name, label, lines} = Nif.get_info(chip)

    %{name: to_charlist(name), label: to_charlist(label), lines: lines}
  end

  def get_line_info(chip, line_offset) do
    {flags, name, consumer} = Nif.get_line_info(chip, line_offset)

    # TODO: unmask flags, move to proper data structure
    %{
      flags: flags,
      name: line_name_to_string_or_nil(name),
      consumer: line_consumer_to_string_or_nil(consumer)
    }
  end

  defp line_name_to_string_or_nil([]), do: nil
  defp line_name_to_string_or_nil(line_name), do: to_string(line_name)

  defp line_consumer_to_string_or_nil([]), do: nil
  defp line_consumer_to_string_or_nil(consumer), do: to_string(consumer)
end
