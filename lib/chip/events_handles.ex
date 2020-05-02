defmodule Circuits.GPIO.Chip.EventsHandles do
  @moduledoc false

  defstruct data: %{}

  def put_event_handle(events_handles, event_ref, event_handle) do
    %__MODULE__{data: data} = events_handles

    %__MODULE__{events_handles | data: Map.put(data, event_ref, event_handle)}
  end

  def get_handle_for_event(events_handles, event_ref) do
    Map.get(events_handles.data, event_ref)
  end
end
