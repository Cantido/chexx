defmodule Chexx.FEN do
  use AbnfParsec,
    abnf_file: "priv/fen.abnf",
    parse: :fenrecord,
    transform: %{
      "piece" => {:reduce, {Chexx.FEN, :build_piece, []}},
      "halfmoves" => [{:reduce, {List, :to_string, []}}, {:map, {String, :to_integer, []}}],
      "fullmoves" => [{:reduce, {List, :to_string, []}}, {:map, {String, :to_integer, []}}],
      "emptyspaces" => [{:reduce, {List, :to_string, []}}, {:map, {String, :to_integer, []}}],
    },
    unwrap: [
      "halfmoves",
      "fullmoves",
      "emptyspaces"
    ],
    unbox: ["piece"],
    untag: ["row"],
    ignore: [
      "slash",
      "space"
    ]
  alias Chexx.Pieces.{
    Bishop,
    King,
    Knight,
    Pawn,
    Queen,
    Rook
  }

  @external_resource "priv/fen.abnf"

  def build_piece('B'), do: %Bishop{color: :white}
  def build_piece('b'), do: %Bishop{color: :black}
  def build_piece('K'), do: %King{color: :white}
  def build_piece('k'), do: %King{color: :black}
  def build_piece('N'), do: %Knight{color: :white}
  def build_piece('n'), do: %Knight{color: :black}
  def build_piece('P'), do: %Pawn{color: :white}
  def build_piece('p'), do: %Pawn{color: :black}
  def build_piece('Q'), do: %Queen{color: :white}
  def build_piece('q'), do: %Queen{color: :black}
  def build_piece('R'), do: %Rook{color: :white}
  def build_piece('r'), do: %Rook{color: :black}
end
