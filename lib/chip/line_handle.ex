defmodule Circuits.GPIO.Chip.LineHandle do
  alias Circuits.GPIO.Chip.{Line, Nif}

  @type direction :: :input | :output

  @opaque t :: %__MODULE__{
            line: Line.t(),
            ref: reference()
          }

  @enforce_keys [:line, :ref]
  defstruct line: nil, ref: nil

  @spec for_line(Line.t(), direction(), keyword()) :: t()
  def for_line(line, direction, opts) do
    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    # add `:default` to opts
    default = 0
    # handle more flags in the future
    flags = flag_from_atom(direction)

    # better error handling
    {:ok, ref} =
      Nif.request_linehandle(Line.chip(line), Line.offset(line), default, flags, consumer)

    %__MODULE__{line: line, ref: ref}
  end

  @spec set_value(t(), 0 | 1) :: :ok
  def set_value(%__MODULE__{ref: ref}, value) do
    Nif.set_value(ref, value)
  end

  @spec get_value(t()) :: 0 | 1
  def get_value(%__MODULE__{ref: ref}) do
    Nif.get_value(ref)
  end

  @spec line(t()) :: Line.t()
  def line(%__MODULE__{line: line}), do: line

  defp flag_from_atom(:input), do: 0x01
  defp flag_from_atom(:output), do: 0x02
end
