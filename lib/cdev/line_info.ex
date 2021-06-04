defmodule Circuits.Cdev.LineInfo do
  @moduledoc """
  Line information
  """

  alias Circuits.Cdev

  @type t() :: %__MODULE__{
          offset: Cdev.offset(),
          name: String.t(),
          consumer: String.t(),
          active_low: boolean(),
          direction: Cdev.line_direction()
        }

  defstruct offset: nil, name: nil, consumer: nil, active_low: nil, direction: nil
end
