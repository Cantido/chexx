defmodule Chexx.GameTest do
  use ExUnit.Case
  alias Chexx.Board
  alias Chexx.Game
  alias Chexx.Square
  alias Chexx.Pieces.{
    Bishop,
    King,
    Knight,
    Pawn,
    Queen,
    Rook
  }
  import Chexx.Square, only: [sigil_q: 2]
  import OK, only: [~>>: 2]
  doctest Chexx.Game

  doctest Chexx.Game

  test "detects stalemate" do
    {:ok, game} =
      {:ok, Board.new()}
      ~>> Board.put_piece(King.black(), ~q[h8])
      ~>> Board.put_piece(King.white(), ~q[f7])
      ~>> Board.put_piece(Queen.white(), ~q[g6])
      ~>> Game.new(:black)

    assert Game.stalemate?(game)
  end

  test "decodes can load a board from FEN" do
    {:ok, game} = Game.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

    assert Board.piece_at(game.board, ~q[a8]) == Rook.black()
    assert Board.piece_at(game.board, ~q[b8]) == Knight.black()
    assert Board.piece_at(game.board, ~q[c8]) == Bishop.black()
    assert Board.piece_at(game.board, ~q[d8]) == Queen.black()
    assert Board.piece_at(game.board, ~q[e8]) == King.black()
    assert Board.piece_at(game.board, ~q[f8]) == Bishop.black()
    assert Board.piece_at(game.board, ~q[g8]) == Knight.black()
    assert Board.piece_at(game.board, ~q[h8]) == Rook.black()

    for file <- ~w[a b c d e f g h]a do
      square = Square.new(file, 7)
      assert Board.piece_at(game.board, square) == Pawn.black()
    end


    for file <- ~w[a b c d e f g h]a do
      for rank <- 3..6 do
        square = Square.new(file, rank)
        assert is_nil(Board.piece_at(game.board, square))
      end
    end


    for file <- ~w[a b c d e f g h]a do
      square = Square.new(file, 2)
      assert Board.piece_at(game.board, square) == Pawn.white()
    end

    assert Board.piece_at(game.board, ~q[a1]) == Rook.white()
    assert Board.piece_at(game.board, ~q[b1]) == Knight.white()
    assert Board.piece_at(game.board, ~q[c1]) == Bishop.white()
    assert Board.piece_at(game.board, ~q[d1]) == Queen.white()
    assert Board.piece_at(game.board, ~q[e1]) == King.white()
    assert Board.piece_at(game.board, ~q[f1]) == Bishop.white()
    assert Board.piece_at(game.board, ~q[g1]) == Knight.white()
    assert Board.piece_at(game.board, ~q[h1]) == Rook.white()

    assert game.current_player == :white
  end

  describe "can load current player from FEN" do
    test "when current player is white" do
      {:ok, game} = Game.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

      assert game.current_player == :white
    end

    test "when current player is black" do
      {:ok, game} = Game.new("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1")

      assert game.current_player == :black
    end
  end
end
