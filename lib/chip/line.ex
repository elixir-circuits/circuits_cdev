defmodule Circuits.GPIO.Chip.Line do
  alias Circuits.GPIO.Chip
  alias Circuits.GPIO.Chip.{Nif, LineInfo, LineHandle}

  @type offset :: non_neg_ineger()

  @opaque t :: %__MODULE__{
            chip: Chip.t(),
            offset: offset()
          }

  @enforce_keys [:chip, :offset]
  defstruct chip: nil, request_handle: nil, offset: nil

  @spec new(Chip.t(), offset()) :: t()
  def new(chip, offset) do
    %__MODULE__{
      chip: chip,
      offset: offset
    }
  end

  @spec info(t()) :: LineInfo.t()
  def info(%__MODULE__{chip: chip, offset: offset}) do
    LineInfo.get(chip, offset)
  end

  @spec request_handle(t(), atom(), keyword) :: LineHandle.t()
  def request_handle(%__MODULE__{} = line, direction, opts \\ []) do
    LineHandle.from_line(line, direction, opts)
  end

  def chip(%__MODULE__{chip: chip}), do: chip

  def offset(%__MODULE__{offset: offset}), do: offset
end
