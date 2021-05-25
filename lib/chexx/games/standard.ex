defmodule Chexx.Games.Standard do
  alias Chexx.Board
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }
  import OK, only: [~>>: 2]

  def new_board do
    white_pawn = %Pawn{color: :white}
    black_pawn = %Pawn{color: :black}
    completed_board =
      {:ok, Board.new()}
      ~>> Board.put_piece(white_pawn, :a, 2)
      ~>> Board.put_piece(white_pawn, :b, 2)
      ~>> Board.put_piece(white_pawn, :c, 2)
      ~>> Board.put_piece(white_pawn, :d, 2)
      ~>> Board.put_piece(white_pawn, :e, 2)
      ~>> Board.put_piece(white_pawn, :f, 2)
      ~>> Board.put_piece(white_pawn, :g, 2)
      ~>> Board.put_piece(white_pawn, :h, 2)

      ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
      ~>> Board.put_piece(%Knight{color: :white}, :b, 1)
      ~>> Board.put_piece(%Bishop{color: :white}, :c, 1)
      ~>> Board.put_piece(%Queen{color: :white}, :d, 1)
      ~>> Board.put_piece(%King{color: :white}, :e, 1)
      ~>> Board.put_piece(%Bishop{color: :white}, :f, 1)
      ~>> Board.put_piece(%Knight{color: :white}, :g, 1)
      ~>> Board.put_piece(%Rook{color: :white}, :h, 1)

      ~>> Board.put_piece(black_pawn, :a, 7)
      ~>> Board.put_piece(black_pawn, :b, 7)
      ~>> Board.put_piece(black_pawn, :c, 7)
      ~>> Board.put_piece(black_pawn, :d, 7)
      ~>> Board.put_piece(black_pawn, :e, 7)
      ~>> Board.put_piece(black_pawn, :f, 7)
      ~>> Board.put_piece(black_pawn, :g, 7)
      ~>> Board.put_piece(black_pawn, :h, 7)

      ~>> Board.put_piece(%Rook{color: :black}, :a, 8)
      ~>> Board.put_piece(%Knight{color: :black}, :b, 8)
      ~>> Board.put_piece(%Bishop{color: :black}, :c, 8)
      ~>> Board.put_piece(%Queen{color: :black}, :d, 8)
      ~>> Board.put_piece(%King{color: :black}, :e, 8)
      ~>> Board.put_piece(%Bishop{color: :black}, :f, 8)
      ~>> Board.put_piece(%Knight{color: :black}, :g, 8)
      ~>> Board.put_piece(%Rook{color: :black}, :h, 8)

    case completed_board do
      {:ok, board} -> board
      err -> raise "Setting up a board resulted in an error. This is a bug in Chexx. Error: #{inspect err}"
    end
  end
end
