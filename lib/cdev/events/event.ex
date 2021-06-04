defmodule Circuits.Cdev.Events.Event do
  @moduledoc false

  alias Circuits.Cdev

  @type t() :: %__MODULE__{
          handle: reference(),
          listener: pid(),
          offset: Cdev.offset(),
          chip: Cdev.chip(),
          last_event: non_neg_integer()
        }

  defstruct handle: nil, listener: nil, offset: nil, chip: nil, last_event: 0
end
