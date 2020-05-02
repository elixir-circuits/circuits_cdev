defmodule Circuits.GPIO.Chip do
  alias Circuits.GPIO.Chip.{Nif, InterruptServer}

  @opaque t :: reference()

  @opaque line_handle :: reference()

  @type direction :: :input | :output

  @type offset :: non_neg_integer()

  @doc """
  Open a GPIO chip

  This is a string in the format of `"gpiochipN"` where `N` is the chip number
  that you want to work with.
  """
  @spec open(String.t()) :: {:ok, t()}
  def open(device) do
    device
    |> normalize_dev_path()
    |> to_charlist()
    |> Nif.open()
  end

  @doc """
  Close a GPIO chip
  """
  @spec close(t()) :: :ok
  def close(chip) do
    Nif.close(chip)
  end

  @doc """
  Request control of a single GPIO line

  ```elixir
  {:ok, handle} = Circuits.GPIO.Chip.Lines.request_handle(chip, 16, :output)
  ```
  """
  @spec request_line(t(), offset(), direction(), keyword()) :: {:ok, line_handle()}
  def request_line(chip, offset_or_offsets, direction, opts \\ [])

  def request_line(chip, offset, direction, opts) when is_integer(offset) do
    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    # add opts for default
    default = 0

    # handle more flags in the future
    flags = flag_from_atom(direction)

    # better error handling
    Nif.request_linehandle(
      chip,
      offset,
      default,
      flags,
      consumer
    )
  end

  def request_line(_, offsets, _, _) when is_list(offsets) do
    raise ArgumentError, """
    Looks like you are trying to request control for many GPIO lines.

    Use `Circuits.GPIO.Chip.request_lines/3` instead.
    """
  end

  @doc """
  Request a line handle to control many GPIO lines
  """
  @spec request_lines(t(), [offset()], direction(), keyword()) :: {:ok, line_handle()}
  def request_lines(chip, offsets, direction, opts \\ [])

  def request_lines(chip, offsets, direction, opts) when is_list(offsets) do
    defaults = get_defaults(opts, length(offsets))

    # handle more flags in the future
    flags = flag_from_atom(direction)

    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    Nif.request_linehandle_multi(
      chip,
      offsets,
      defaults,
      flags,
      consumer
    )
  end

  def request_lines(_, offset, _, _) when is_integer(offset) do
    raise ArgumentError, """
    Looks like you are trying to control a single GPIO line.

    Use `Circuits.GPIO.Chip.request_line/3` instead.
    """
  end

  @doc """
  trigger = :rising | :falling | :both
  """
  def set_interrupt(chip, offset, trigger, opts \\ []) do
    InterruptServer.set_interrupt(chip, offset, trigger, opts)
  end

  @spec get_value(line_handle()) :: 0 | 1
  def get_value(handle), do: Nif.get_value(handle)

  @spec set_value(line_handle(), 0 | 1) :: :ok
  def set_value(handle, value), do: Nif.set_value(handle, value)

  @spec set_values(line_handle(), [0 | 1]) :: :ok
  def set_values(handle, values), do: Nif.set_values(handle, values)

  defp normalize_dev_path(dev_path) do
    if String.contains?(dev_path, "/dev") do
      dev_path
    else
      Path.join("/dev", dev_path)
    end
  end

  defp flag_from_atom(:input), do: 0x01
  defp flag_from_atom(:output), do: 0x02

  defp get_defaults(opts, defaults_length) do
    case Keyword.get(opts, :defaults) do
      nil ->
        for _ <- 1..defaults_length, do: 0

      defaults ->
        if length(defaults) == defaults_length do
          defaults
        else
          raise ArgumentError
        end
    end
  end
end
