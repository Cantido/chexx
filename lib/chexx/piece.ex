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

  def to_unicode(%__MODULE__{type: type, color: color}) do
    case {color, type} do
      {:white, :king} -> "♔"
      {:white, :queen} -> "♕"
      {:white, :rook} -> "♖"
      {:white, :bishop} -> "♗"
      {:white, :knight} -> "♘"
      {:white, :pawn} -> "♙"
      {:black, :king} -> "♚"
      {:black, :queen} -> "♛"
      {:black, :rook} -> "♜"
      {:black, :bishop} -> "♝"
      {:black, :knight} -> "♞"
      {:black, :pawn} -> "♟︎"
    end
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(piece, _opts) do
      Chexx.Piece.to_unicode(piece)
    end
  end
end
