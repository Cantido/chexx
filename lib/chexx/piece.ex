defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """

  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }

  @type t() ::
    Chexx.Pieces.King.t() |
    Chexx.Pieces.Queen.t() |
    Chexx.Pieces.Rook.t() |
    Chexx.Pieces.Bishop.t() |
    Chexx.Pieces.Knight.t() |
    Chexx.Pieces.Pawn.t()

  def to_string(%King{color: :white}), do: "♔"
  def to_string(%Queen{color: :white}), do: "♕"
  def to_string(%Rook{color: :white}), do: "♖"
  def to_string(%Bishop{color: :white}), do: "♗"
  def to_string(%Knight{color: :white}), do: "♘"
  def to_string(%Pawn{color: :white}), do: "♙"

  def to_string(%King{color: :black}), do: "♚"
  def to_string(%Queen{color: :black}), do: "♛"
  def to_string(%Rook{color: :black}), do: "♜"
  def to_string(%Bishop{color: :black}), do: "♝"
  def to_string(%Knight{color: :black}), do: "♞"
  def to_string(%Pawn{color: :black}), do: "♟︎"

  def moves_from(%King{} = piece, square), do: King.possible_king_moves(piece, square)
  def moves_from(%Queen{} = piece, square), do: Queen.possible_queen_moves(piece, square)
  def moves_from(%Rook{} = piece, square), do: Rook.possible_rook_moves(piece, square)
  def moves_from(%Bishop{} = piece, square), do: Bishop.possible_bishop_moves(piece, square)
  def moves_from(%Knight{} = piece, square), do: Knight.possible_knight_moves(piece, square)
  def moves_from(%Pawn{} = piece, square), do: Pawn.possible_pawn_moves(piece, square)

  def moves_to(%King{} = piece, square), do: King.possible_king_sources(piece, square)
  def moves_to(%Queen{} = piece, square), do: Queen.possible_queen_sources(piece, square)
  def moves_to(%Rook{} = piece, square), do: Rook.possible_rook_sources(piece, square)
  def moves_to(%Bishop{} = piece, square), do: Bishop.possible_bishop_sources(piece, square)
  def moves_to(%Knight{} = piece, square), do: Knight.possible_knight_sources(piece, square)
  def moves_to(%Pawn{} = piece, square), do: Pawn.possible_pawn_sources(piece, square)

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
