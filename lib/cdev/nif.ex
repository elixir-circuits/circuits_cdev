defmodule Circuits.Cdev.Nif do
  @moduledoc false

  # Lower level nif bindings

  @on_load {:load_nif, 0}
  @compile {:autoload, false}

  alias Circuits.Cdev

  def load_nif() do
    nif_binary = Application.app_dir(:circuits_cdev, "priv/cdev_nif")

    :erlang.load_nif(to_charlist(nif_binary), 0)
  end

  @doc """
  Open a GPIO chip
  """
  @spec chip_open_nif(charlist()) :: {:ok, reference()} | {:error, atom}
  def chip_open_nif(_path) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Get the information about a chip
  """
  @spec get_chip_info_nif(reference()) ::
          {:ok, name :: charlist(), label :: charlist(), num_lines :: non_neg_integer()}
          | {:error, atom()}
  def get_chip_info_nif(_chip_ref) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Get the information about a line
  """
  @spec get_line_info_nif(reference(), Cdev.offset()) ::
          {:ok, name :: charlist(), consumer :: charlist(), active_low :: non_neg_integer(),
           open_drain :: non_neg_integer()}
          | {:error, atom()}
  def get_line_info_nif(_chip_ref, _offset) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Listen for an event

  This function requires an event handle and a event data resource.
  """
  @spec listen_event_nif(reference(), reference(), reference()) :: :ok | {:error, atom()}
  def listen_event_nif(_event_handle, _event_data, _ref) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Get an event data resource to be used with for listening for events.
  """
  @spec make_event_data_nif(reference()) :: {:ok, reference()} | {:error, atom()}
  def make_event_data_nif(_event_handle) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Read the event data from the event handle
  """
  @spec read_event_data_nif(reference(), reference()) ::
          {:ok, value :: non_neg_integer(), timestamp :: non_neg_integer()} | {:error, atom()}
  def read_event_data_nif(_event_handle, _event_data) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Read a list of values from the line handle
  """
  @spec read_values_nif(reference()) :: {:ok, [Cdev.offset_value()]} | {:error, atom()}
  def read_values_nif(_line_handle_ref) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Request an event handle to be used for listening for events
  """
  @spec request_event_nif(reference(), Cdev.offset()) :: {:ok, reference()} | {:error, atom()}
  def request_event_nif(_chip_ref, _offset) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Request lines to control
  """
  @spec request_lines_nif(reference(), [Cdev.offset()], 0 | 1) ::
          {:ok, reference()} | {:error, atom()}
  def request_lines_nif(_chip_ref, _offset, _direction) do
    :erlang.nif_error(:nif_not_loaded)
  end

  @doc """
  Set the values of the GPIO line(s)
  """
  @spec set_values_nif(reference(), [Cdev.offset_value()]) :: :ok | {:error, atom()}
  def set_values_nif(_handle_ref, _values) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
