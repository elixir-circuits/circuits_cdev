defmodule Circuits.GPIO.Chip.LineHandleMulti do
  alias Circuits.GPIO.Chip.{Line, Nif}

  @opaque t :: %__MODULE__{
            lines: [Line.t()],
            ref: reference()
          }

  defstruct lines: [], ref: nil

  def for_lines([line | _] = lines, direction, opts \\ []) do
    chip = Line.chip(line)
    offsets = Enum.map(lines, &Line.offset/1)
    defaults = get_defaults(opts, length(offsets))

    # handle more flags in the future
    flags = flag_from_atom(direction)

    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    {:ok, ref} =
      Nif.request_linehandle_multi(
        chip,
        offsets,
        defaults,
        flags,
        consumer
      )

    %__MODULE__{lines: lines, ref: ref}
  end

  def set_values(%__MODULE__{ref: handle}, values) do
    Nif.set_values(handle, values)
  end

  defp flag_from_atom(:input), do: 0x01
  defp flag_from_atom(:output), do: 0x02

  defp get_defaults(opts, defaults_length) do
    case Keyword.get(opts, :defaults) do
      nil ->
        Enum.reduce(1..defaults_length, [], fn _, defaults -> [0 | defaults] end)

      defaults ->
        if length(defaults) == defaults_length do
          defaults
        else
          raise ArgumentError
        end
    end
  end
end
