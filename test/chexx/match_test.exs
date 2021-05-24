defmodule Chexx.GameTest do
  use ExUnit.Case
  alias Chexx.Board
  alias Chexx.Game
  alias Chexx.Pieces.{
    King, Queen
  }
  import OK, only: [~>>: 2]

  doctest Chexx.Game

  test "detects stalemate" do
    {:ok, game} =
      {:ok, Board.new()}
      ~>> Board.put_piece(%King{color: :black}, 8, 8)
      ~>> Board.put_piece(%King{color: :white}, 6, 7)
      ~>> Board.put_piece(%Queen{color: :white}, 7, 6)
      ~>> Game.new(:black)

    assert Game.stalemate?(game)
  end
end
