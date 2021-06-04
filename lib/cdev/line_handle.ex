defmodule Circuits.Cdev.LineHandle do
  @moduledoc """
  A handle to read and set values to GPIO line(s)
  """

  alias Circuits.Cdev

  @type t() :: %__MODULE__{
          chip: Cdev.chip(),
          handle: reference()
        }

  defstruct chip: nil, handle: nil
end
