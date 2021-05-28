defmodule Chexx.Touches.Travel do
  @moduledoc """
  The act of touching and moving a piece.
  Encodes a start square and end square.
  """

  @type t() :: %__MODULE__{
    source: Chexx.Square.t(),
    destination: Chexx.Square.t(),
    piece: Chexx.Piece.t()
  }

  @enforce_keys [
    :source,
    :destination,
    :piece
  ]
  defstruct [
    :source,
    :destination,
    :piece
  ]
end
