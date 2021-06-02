defmodule Chexx.GameTest do
  use ExUnit.Case
  alias Chexx.Board
  alias Chexx.Game
  alias Chexx.Pieces.{
    Bishop,
    King,
    Knight,
    Pawn,
    Queen,
    Rook
  }
  doctest Chexx.Game

  test "decodes can load a board from FEN" do
    {:ok, game} = Game.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

    assert Board.piece_at(game.board, :a, 8) == %Rook{color: :black}
    assert Board.piece_at(game.board, :b, 8) == %Knight{color: :black}
    assert Board.piece_at(game.board, :c, 8) == %Bishop{color: :black}
    assert Board.piece_at(game.board, :d, 8) == %Queen{color: :black}
    assert Board.piece_at(game.board, :e, 8) == %King{color: :black}
    assert Board.piece_at(game.board, :f, 8) == %Bishop{color: :black}
    assert Board.piece_at(game.board, :g, 8) == %Knight{color: :black}
    assert Board.piece_at(game.board, :h, 8) == %Rook{color: :black}

    for file <- ~w[a b c d e f g h]a do
      assert Board.piece_at(game.board, file, 7) == %Pawn{color: :black}
    end


    for file <- ~w[a b c d e f g h]a do
      for rank <- 3..6 do
        assert is_nil(Board.piece_at(game.board, file, rank))
      end
    end


    for file <- ~w[a b c d e f g h]a do
      assert Board.piece_at(game.board, file, 2) == %Pawn{color: :white}
    end

    assert Board.piece_at(game.board, :a, 1) == %Rook{color: :white}
    assert Board.piece_at(game.board, :b, 1) == %Knight{color: :white}
    assert Board.piece_at(game.board, :c, 1) == %Bishop{color: :white}
    assert Board.piece_at(game.board, :d, 1) == %Queen{color: :white}
    assert Board.piece_at(game.board, :e, 1) == %King{color: :white}
    assert Board.piece_at(game.board, :f, 1) == %Bishop{color: :white}
    assert Board.piece_at(game.board, :g, 1) == %Knight{color: :white}
    assert Board.piece_at(game.board, :h, 1) == %Rook{color: :white}

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
