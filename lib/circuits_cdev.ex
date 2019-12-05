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

    def get_info(_chip_ref) do
      :erlang.nif_error(:nif_not_loaded)
    end
  end

  @spec open(String.t()) :: {:ok, reference()}
  def open(chip_device) do
    chip_device
    |> to_charlist()
    |> Nif.open()
  end

  @spec get_info(reference()) :: %{name: String.t(), label: String.t(), lines: integer()}
  def get_info(chip) do
    {name, label, lines} = Nif.get_info(chip)

    %{name: to_charlist(name), label: to_charlist(label), lines: lines}
  end
end
