defmodule Circuits.GPIO.Chip.Events.Event do
  @moduledoc false

  @type t() :: %__MODULE__{
          handle: reference(),
          listener: pid(),
          offset: Chip.offset(),
          chip: Chip.t(),
          last_event: non_neg_integer()
        }

  defstruct handle: nil, listener: nil, offset: nil, chip: nil, last_event: 0
end
