defmodule Circuits.Cdev do
  @moduledoc """
  Control GPIOs using Linux GPIO character device interface

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

  alias Circuits.Cdev.{Events, LineHandle, LineInfo, Nif}

  @type chip() :: %{
          name: String.t(),
          label: String.t(),
          number_of_lines: non_neg_integer(),
          reference: reference()
        }

  @typedoc """
  The offset of the pin

  An offset is the pin number provided. Normally these are labeled `GPIO N` or
  `GPIO_N` where `N` is the pin number. For example, if you wanted to use to
  use `GPIO 17` on a Raspberry PI the offset value would be `17`.

  More resources:

  Raspberry PI: https://pinout.xyz/
  Beaglebone: https://beagleboard.org/Support/bone101
  """
  @type offset() :: non_neg_integer()

  @typedoc """
  The value of the offset

  This is either 0 for low or off, or 1 for high or on.
  """
  @type offset_value() :: 0 | 1

  @typedoc """
  The direction of the line

  With the character device you drive a line with configured offsets. These
  offsets all share a direction, either `:output` or `:input`, which is called
  the line direction.

  The `:output` direction means you control the GPIOs by setting the value of
  the GPIOs to 1 or 0. See `Circuits.Cdev.set_value/2` for more
  information.

  The `:input` direction means you can only read the current value of the GPIOs
  on the line. See `Circuits.GPIO.read_value/1` for more information.
  """
  @type line_direction() :: :input | :output

  @doc """
  Getting information about a line
  """
  @spec get_line_info(chip(), offset()) :: {:ok, LineInfo.t()} | {:error, atom()}
  def get_line_info(chip, offset) do
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
  Listen to line events on the line offset

  ```elixir
  Circuits.Cdev.listen_event(mygpio_chip, 24)
  # cause the offset to change value
  flush
  {:circuits_cdev, 24, timestamp, new_value}
  ```

  The timestamp will be in nanoseconds so as you do time calculations and
  conversions be sure to take that into account.

  The `new_value` will be the value the offset value changed to either `1` or
  `0`.
  """
  @spec listen_event(chip() | String.t(), offset()) :: :ok
  def listen_event(chip_name, offset) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} -> listen_event(chip, offset)
    end
  end

  def listen_event(chip, offset) do
    Events.listen_event(chip, offset)
  end

  @doc """
  Open a GPIO Chip

  ```elixir
  {:ok, chip} = Circuits.Cdev.open(gpiochip_device)
  ```
  """
  @spec open(String.t()) :: {:ok, chip()}
  def open(chip_name) do
    chip_name = Path.join("/dev", chip_name)
    {:ok, ref} = Nif.chip_open_nif(to_charlist(chip_name))
    {:ok, name, label, number_of_lines} = Nif.get_chip_info_nif(ref)

    {:ok,
     %{
       name: to_string(name),
       label: to_string(label),
       number_of_lines: number_of_lines,
       reference: ref
     }}
  end

  @doc """
  Read value from a line handle

  This is useful when you have a line handle that contains only one GPIO
  offset.

  If you want to read multiple GPIOs at once see
  `Circuits.Cdev.read_values/1`.

  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_line("gpiochip0", 17)
  {:ok, 0} = Circuits.Cdev.read_value(line_handle)
  ```
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

  This is useful when you a line handle that contains multiple GPIO offsets.

  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_lines("gpiochip0", [17, 22, 23, 24])
  {:ok, [0, 0, 0, 0]} = Circuits.Cdev.read_values(line_handle)
  ```

  Note that the values in the list match the index order of how the offsets were
  requested.

  Note that the order of the values returned return the order that the offsets
  were requested.
  """
  @spec read_values(LineHandle.t()) :: {:ok, [offset_value()]} | {:error, atom()}
  def read_values(line_handle) do
    %LineHandle{handle: handle} = line_handle

    Nif.read_values_nif(handle)
  end

  @doc """
  Request a line handle for a single GPIO offset


  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_line(my_gpio_chip, 17, :output)
  ```

  See `Circuits.Cdev.request_lines/3` and `Circuits.Cdev.LineHandle` for
  more details about line handles.
  """
  @spec request_line(chip() | String.t(), offset(), line_direction()) :: {:ok, LineHandle.t()}
  def request_line(chip_name, offset, direction) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} ->
        request_lines(chip, [offset], direction)
    end
  end

  def request_line(chip, offset, direction) do
    request_lines(chip, [offset], direction)
  end

  @doc """
  Request a line handle for multiple GPIO offsets

  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_lines(my_gpio_chip, [17, 24], :output)
  ```

  For the GPIO character device driver you drive GPIOs by requesting for a line
  handle what contains one or more GPIO offsets. The line handle is mechanism
  by which you can read and set the values of the GPIO(s). The line handle is
  attached to the calling process and kernel will not allow others to control
  the GPIO(s) that are part of that the line handle. Moreover, one the process
  that requested the line handle goes away the kernel will be able to
  automatically free the system resources that were tied to that line handle.
  """
  @spec request_lines(chip() | String.t(), [offset()], line_direction()) :: {:ok, LineHandle.t()}
  def request_lines(chip_name, offsets, direction) when is_binary(chip_name) do
    case open(chip_name) do
      {:ok, chip} ->
        request_lines(chip, offsets, direction)
    end
  end

  def request_lines(chip, offsets, direction) do
    {:ok, handle} = Nif.request_lines_nif(chip.reference, offsets, direction_from_atom(direction))

    {:ok, %LineHandle{chip: chip, handle: handle}}
  end

  @doc """
  Set the value of the GPIO

  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_lines(my_gpio_chip, 17)
  {:ok, 0} = Circuits.Cdev.read_value(line_handle)
  :ok = Circuits.Cdev.set_value(line_handle, 1)
  {:ok, 1} = Circuits.Cdev.read_value(line_handle)
  ```
  """
  @spec set_value(LineHandle.t(), offset_value()) :: :ok | {:error, atom()}
  def set_value(handle, value) do
    set_values(handle, [value])
  end

  @doc """
  Set values of the GPIOs

  ```elixir
  {:ok, line_handle} = Circuits.Cdev.request_lines(my_gpio_chip, [17, 24, 22])
  {:ok, [0, 0, 0]} = Circuits.Cdev.read_value(line_handle)
  :ok = Circuits.Cdev.set_value(line_handle, [1, 0, 1])
  {:ok, [1, 0, 1]} = Circuits.Cdev.read_value(line_handle)
  ```

  Note that the order of the values that were sent matches the order by which
  the GPIO offsets where requested. In the example above offset 17 was set to
  1, offset 24 was stayed at 0, offset 22 was set to 1.
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
