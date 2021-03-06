defmodule Chexx.PGN.ParserTest do
  use ExUnit.Case, async: true
  doctest Chexx.PGN.Parser

  test "decodes a single game" do
    pgn = File.read!("test/fixtures/PGN/fischer-spassky-1992.pgn")

    [game] = Chexx.PGN.Parser.parse!(pgn)

    assert game.tags["Event"] == "F/S Return Match"
    assert Enum.at(game.moves, 0).white_move == "e4"
    assert game.termination == "1/2-1/2"
  end
end
