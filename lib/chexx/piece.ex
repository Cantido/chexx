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
