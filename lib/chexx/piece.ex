defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """

  import Chexx.Color

  defguard is_piece(piece) when
    piece == :king or
    piece == :queen or
    piece == :rook or
    piece == :bishop or
    piece == :knight or
    piece == :pawn

  @enforce_keys [
    :type,
    :color
  ]
  defstruct [
    :type,
    :color
  ]

  def new(type, color) when is_piece(type) and is_color(color) do
    %__MODULE__{type: type, color: color}
  end
end
