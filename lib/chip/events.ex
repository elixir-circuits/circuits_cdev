defmodule Circuits.GPIO.Chip.Events do
  @moduledoc false

  use GenServer

  alias Circuits.GPIO.Chip
  alias Circuits.GPIO.Chip.Nif
  alias Circuits.GPIO.Chip.Events.Event

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Listen to line events on the offset
  """
  @spec listen_event(Chip.t(), Chip.offset()) :: :ok
  def listen_event(chip, offset) do
    GenServer.call(__MODULE__, {:listen_event, chip, offset, self()})
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:listen_event, chip, offset, listener}, _from, state) do
    {:ok, event_handle} = Nif.request_event_nif(chip.reference, offset)
    {:ok, event_data} = Nif.make_event_data_nif(event_handle)

    event_ref = make_ref()

    :ok = Nif.listen_event_nif(event_handle, event_data, event_ref)

    event = %Event{
      handle: event_handle,
      listener: listener,
      offset: offset,
      chip: chip
    }

    state = Map.put(state, event_ref, event)

    {:reply, :ok, Map.put(state, event_ref, event)}
  end

  @impl GenServer
  def handle_info({:select, event_data_ref, event_ref, :ready_input}, state) do
    %Event{
      handle: event_handle,
      listener: listener,
      last_event: last_event,
      offset: offset
    } = event = Map.fetch!(state, event_ref)

    {:ok, event_value, timestamp} = Nif.read_event_data_nif(event_handle, event_data_ref)

    if event_value != last_event do
      send(
        listener,
        {:circuits_cdev, offset, timestamp, event_value_to_offset_value(event_value)}
      )
    end

    :ok = Nif.listen_event_nif(event_handle, event_data_ref, event_ref)

    event = %Event{event | last_event: event_value}

    {:noreply, Map.update!(state, event_ref, fn _ -> event end)}
  end

  defp event_value_to_offset_value(1), do: 1
  defp event_value_to_offset_value(2), do: 0
end
