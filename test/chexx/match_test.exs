defmodule Chexx.GameTest do
  use ExUnit.Case
  alias Chexx.Board
  alias Chexx.Game
  import OK, only: [~>>: 2]

  doctest Chexx.Game

  test "detects stalemate" do
    {:ok, game} =
      {:ok, Board.new()}
      ~>> Board.put_piece(:king, :black, 8, 8)
      ~>> Board.put_piece(:king, :white, 6, 7)
      ~>> Board.put_piece(:queen, :white, 7, 6)
      ~>> Game.new(:black)

    assert Game.stalemate?(game)
  end
end
