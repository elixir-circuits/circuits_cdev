defmodule Circuits.GPIO.Chip.LineHandle do
  @moduledoc """
  A handle to read and set values to GPIO line(s)
  """

  alias Circuits.GPIO.Chip

  @type t() :: %__MODULE__{
          chip: Chip.t(),
          handle: reference()
        }

  defstruct chip: nil, handle: nil
end
