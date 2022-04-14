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
  import Chexx.Square, only: [sigil_q: 2]
  import OK, only: [~>>: 2]

  def new_board do
    white_pawn = Pawn.white()
    black_pawn = Pawn.black()
    completed_board =
      {:ok, Board.new()}
      ~>> Board.put_piece(white_pawn, ~q[a2])
      ~>> Board.put_piece(white_pawn, ~q[b2])
      ~>> Board.put_piece(white_pawn, ~q[c2])
      ~>> Board.put_piece(white_pawn, ~q[d2])
      ~>> Board.put_piece(white_pawn, ~q[e2])
      ~>> Board.put_piece(white_pawn, ~q[f2])
      ~>> Board.put_piece(white_pawn, ~q[g2])
      ~>> Board.put_piece(white_pawn, ~q[h2])

      ~>> Board.put_piece(Rook.white(), ~q[a1])
      ~>> Board.put_piece(Knight.white(), ~q[b1])
      ~>> Board.put_piece(Bishop.white(), ~q[c1])
      ~>> Board.put_piece(Queen.white(), ~q[d1])
      ~>> Board.put_piece(King.white(), ~q[e1])
      ~>> Board.put_piece(Bishop.white(), ~q[f1])
      ~>> Board.put_piece(Knight.white(), ~q[g1])
      ~>> Board.put_piece(Rook.white(), ~q[h1])

      ~>> Board.put_piece(black_pawn, ~q[a7])
      ~>> Board.put_piece(black_pawn, ~q[b7])
      ~>> Board.put_piece(black_pawn, ~q[c7])
      ~>> Board.put_piece(black_pawn, ~q[d7])
      ~>> Board.put_piece(black_pawn, ~q[e7])
      ~>> Board.put_piece(black_pawn, ~q[f7])
      ~>> Board.put_piece(black_pawn, ~q[g7])
      ~>> Board.put_piece(black_pawn, ~q[h7])

      ~>> Board.put_piece(Rook.black(), ~q[a8])
      ~>> Board.put_piece(Knight.black(), ~q[b8])
      ~>> Board.put_piece(Bishop.black(), ~q[c8])
      ~>> Board.put_piece(Queen.black(), ~q[d8])
      ~>> Board.put_piece(King.black(), ~q[e8])
      ~>> Board.put_piece(Bishop.black(), ~q[f8])
      ~>> Board.put_piece(Knight.black(), ~q[g8])
      ~>> Board.put_piece(Rook.black(), ~q[h8])

    case completed_board do
      {:ok, board} -> board
      err -> raise "Setting up a board resulted in an error. This is a bug in Chexx. Error: #{inspect err}"
    end
  end
end
