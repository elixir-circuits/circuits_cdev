defmodule Circuits.GPIO.Chip do
  @moduledoc """
  Control GPIOs using the GPIO chip interface

  With the character device driver for GPIOs there three concepts to learn.

  First, the API is made up of chips and lines that are grouped together for
  that chip. A chip is more of a grouping identifier than anything physical
  property about the board.

  Secondly, the API requires us to request lines from a GPIO chip. The reason
  for this is the kernel can provide control over who "owns" that line and
  prevent multiple programs from trying to control the same GPIO pin.

  Lastly, you can listen for events on a line. These events report if the line
  is high or low.

  Generally speaking the character device driver allows more fine grain control
  and more reliability than the `sysfs` API.
  """

  alias Circuits.GPIO.Chip.{Events, LineHandle, LineInfo, Nif}

  @type t() :: %__MODULE__{
          name: String.t(),
          label: String.t(),
          number_of_lines: non_neg_integer(),
          reference: reference()
        }

  @typedoc """
  Explain offset
  """
  @type offset() :: non_neg_integer()

  @typedoc """
  Explain offset value
  """
  @type offset_value() :: 0 | 1

  @typedoc """
  Explain line direction
  """
  @type line_direction() :: :input | :output

  defstruct name: nil, label: nil, number_of_lines: 0, reference: nil

  @doc """
  Getting information about a line
  """
  @spec get_line_info(t(), offset()) :: {:ok, LineInfo.t()} | {:error, atom()}
  def get_line_info(%__MODULE__{} = chip, offset) do
    case Nif.get_line_info_nif(chip.reference, offset) do
      {:ok, name, consumer, direction, active_low} ->
        {:ok,
         %LineInfo{
           offset: offset,
           name: to_string(name),
           consumer: to_string(consumer),
           direction: direction_to_atom(direction),
           active_low: active_low_int_to_bool(active_low)
         }}

      error ->
        error
    end
  end

  @doc """
  """
  @spec listen_event(t() | String.t(), offset()) :: :ok
  def listen_event(%__MODULE__{} = chip, offset) do
    Events.listen_event(chip, offset)
  end

  def listen_event(chip_name, offset) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} -> listen_event(chip, offset)
    end
  end

  @doc """
  Open a GPIO Chip

  ```elixir
  ```
  """
  @spec open(String.t()) :: {:ok, t()}
  def open(chip_name) do
    chip_name = Path.join("/dev", chip_name)
    {:ok, ref} = Nif.chip_open_nif(to_charlist(chip_name))
    {:ok, name, label, number_of_lines} = Nif.get_chip_info_nif(ref)

    {:ok,
     %__MODULE__{
       name: to_string(name),
       label: to_string(label),
       number_of_lines: number_of_lines,
       reference: ref
     }}
  end

  @doc """
  Read value from a line handle
  """
  @spec read_value(LineHandle.t()) :: {:ok, offset_value()} | {:error, atom()}
  def read_value(line_handle) do
    case read_values(line_handle) do
      {:ok, [value]} ->
        {:ok, value}

      error ->
        error
    end
  end

  @doc """
  Read values for a line handle
  """
  @spec read_values(LineHandle.t()) :: {:ok, [offset_value()]} | {:error, atom()}
  def read_values(line_handle) do
    %LineHandle{handle: handle} = line_handle

    Nif.read_values_nif(handle)
  end

  @doc """
  Request a line handle for a single line
  """
  @spec request_line(t() | String.t(), offset(), line_direction()) :: {:ok, LineHandle.t()}
  def request_line(%__MODULE__{} = chip, offset, direction) do
    request_lines(chip, [offset], direction)
  end

  def request_line(chip_name, offset, direction) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} ->
        request_lines(chip, [offset], direction)
    end
  end

  @doc """
  Request a line handle for many lines
  """
  @spec request_lines(t() | String.t(), [offset()], line_direction()) :: {:ok, LineHandle.t()}
  def request_lines(%__MODULE__{} = chip, offsets, direction) do
    {:ok, handle} = Nif.request_lines_nif(chip.reference, offsets, direction_from_atom(direction))

    {:ok, %LineHandle{chip: chip, handle: handle}}
  end

  def request_lines(chip_name, offsets, direction) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} ->
        request_lines(chip, offsets, direction)
    end
  end

  @doc """
  ASDF
  """
  @spec set_value(LineHandle.t(), offset_value()) :: :ok | {:error, atom()}
  def set_value(handle, value) do
    set_values(handle, [value])
  end

  @doc """
  Set values of the GPIO lines
  """
  @spec set_values(LineHandle.t(), [offset_value()]) :: :ok | {:error, atom()}
  def set_values(line_handle, values) do
    %LineHandle{handle: handle} = line_handle
    Nif.set_values_nif(handle, values)
  end

  defp direction_from_atom(:input), do: 0
  defp direction_from_atom(:output), do: 1

  defp direction_to_atom(0), do: :input
  defp direction_to_atom(1), do: :output

  defp active_low_int_to_bool(0), do: false
  defp active_low_int_to_bool(1), do: true
end
