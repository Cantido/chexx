defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """

  alias Chexx.Ply
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }

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

  def new(:king, color) when is_color(color), do: %King{color: color}
  def new(:queen, color) when is_color(color), do: %Queen{color: color}
  def new(:rook, color) when is_color(color), do: %Rook{color: color}
  def new(:bishop, color) when is_color(color), do: %Bishop{color: color}
  def new(:knight, color) when is_color(color), do: %Knight{color: color}
  def new(:pawn, color) when is_color(color), do: %Pawn{color: color}

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

  def moves_from(%King{color: color}, square), do: Ply.possible_king_moves(color, square)
  def moves_from(%Queen{color: color}, square), do: Ply.possible_queen_moves(color, square)
  def moves_from(%Rook{color: color}, square), do: Ply.possible_rook_moves(color, square)
  def moves_from(%Bishop{color: color}, square), do: Ply.possible_bishop_moves(color, square)
  def moves_from(%Knight{color: color}, square), do: Ply.possible_knight_moves(color, square)
  def moves_from(%Pawn{color: color}, square), do: Ply.possible_pawn_moves(color, square)

  def moves_to(%King{color: color}, square), do: Ply.possible_king_sources(color, square)
  def moves_to(%Queen{color: color}, square), do: Ply.possible_queen_sources(color, square)
  def moves_to(%Rook{color: color}, square), do: Ply.possible_rook_sources(color, square)
  def moves_to(%Bishop{color: color}, square), do: Ply.possible_bishop_sources(color, square)
  def moves_to(%Knight{color: color}, square), do: Ply.possible_knight_sources(color, square)
  def moves_to(%Pawn{color: color}, square), do: Ply.possible_pawn_sources(color, square)


  def type(%King{}), do: :king
  def type(%Queen{}), do: :queen
  def type(%Rook{}), do: :rook
  def type(%Bishop{}), do: :bishop
  def type(%Knight{}), do: :knight
  def type(%Pawn{}), do: :pawn

  def color(%King{color: color}), do: color
  def color(%Queen{color: color}), do: color
  def color(%Rook{color: color}), do: color
  def color(%Bishop{color: color}), do: color
  def color(%Knight{color: color}), do: color
  def color(%Pawn{color: color}), do: color
end
