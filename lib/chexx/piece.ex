defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """

  alias Chexx.Ply

  import Chexx.Color

  @type piece() :: :king | :queen | :rook | :bishop | :knight | :pawn
  @type t() :: %__MODULE__{
    type: piece(),
    color: Chexx.Color.t()
  }

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

  @spec new(piece(), Chexx.Color.t()) :: t()
  def new(type, color) when is_piece(type) and is_color(color) do
    %__MODULE__{type: type, color: color}
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{type: type, color: color}) do
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

  def equals?(%__MODULE__{type: piece_type, color: piece_color}, color, type) do
    piece_type == type and piece_color == color
  end

  def moves_from(%__MODULE__{type: :king, color: color}, square), do: Ply.possible_king_moves(color, square)
  def moves_from(%__MODULE__{type: :queen, color: color}, square), do: Ply.possible_queen_moves(color, square)
  def moves_from(%__MODULE__{type: :rook, color: color}, square), do: Ply.possible_rook_moves(color, square)
  def moves_from(%__MODULE__{type: :bishop, color: color}, square), do: Ply.possible_bishop_moves(color, square)
  def moves_from(%__MODULE__{type: :knight, color: color}, square), do: Ply.possible_knight_moves(color, square)
  def moves_from(%__MODULE__{type: :pawn, color: color}, square), do: Ply.possible_pawn_moves(color, square)

  defimpl Inspect, for: __MODULE__ do
    def inspect(piece, _opts) do
      Chexx.Piece.to_string(piece)
    end
  end
end
