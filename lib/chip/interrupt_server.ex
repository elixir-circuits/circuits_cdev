defmodule Circuits.GPIO.Chip.InterruptServer do
  @moduledoc false
  use GenServer

  alias Circuits.GPIO.Chip.{Nif, EventsHandles}

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def set_interrupt(chip, offset, trigger, opts \\ []) do
    opts = Keyword.put_new(opts, :receiver, self())
    GenServer.call(__MODULE__, {:set_interrupt, chip, offset, trigger, opts})
  end

  def init(_) do
    {:ok, %EventsHandles{}}
  end

  def handle_call({:set_interrupt, chip, offset, _trigger, opts}, _from, state) do
    event_ref = make_ref()

    consumer =
      opts
      |> Keyword.get(:consumer, "circuits_cdev")
      |> to_charlist()

    # hard coded for now (:both)
    trigger_byte = 0x03

    {:ok, event_handle} =
      Nif.request_lineevent(
        chip,
        offset,
        trigger_byte,
        consumer,
        event_ref
      )

    {:reply, :ok, EventsHandles.put_event_handle(state, event_ref, {offset, event_handle, opts})}
  end

  def handle_info({:select, data_ref, event_ref, :ready_input}, events_handles) do
    case EventsHandles.get_handle_for_event(events_handles, event_ref) do
      nil ->
        Logger.warn("Wut you talkin' about Willis?")
        {:noreply, events_handles}

      {offset, handle_ref, opts} ->
        {value, timestamp} = Nif.read_interrupt(data_ref, handle_ref, event_ref)
        receiver = Keyword.fetch!(opts, :receiver)

        send(receiver, {:circuits_cdev, offset, timestamp, value})
        {:noreply, events_handles}
    end
  end
end
