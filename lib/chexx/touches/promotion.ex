defmodule Chexx.Touches.Promotion do
  @type t() :: %__MODULE__{
    source: Chexx.Square.t(),
    promoted_to: Chexx.Piece.t()
  }

  @enforce_keys [
    :source,
    :promoted_to
  ]
  defstruct [
    :source,
    :promoted_to
  ]
end
