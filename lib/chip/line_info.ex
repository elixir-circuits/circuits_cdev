defmodule Circuits.GPIO.Chip.LineInfo do
  @moduledoc """
  Line information
  """

  alias Circuits.GPIO.Chip

  @type t() :: %__MODULE__{
          offset: Chip.offset(),
          name: String.t(),
          consumer: String.t(),
          active_low: boolean(),
          direction: Chip.line_direction()
        }

  defstruct offset: nil, name: nil, consumer: nil, active_low: nil, direction: nil
end
