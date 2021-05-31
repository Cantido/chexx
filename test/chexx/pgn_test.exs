defmodule Chexx.PGNTest do
  use ExUnit.Case, async: true
  doctest Chexx.PGN

  test "decodes a single game" do
    pgn = File.read!("test/fixtures/PGN/fischer-spassky-1992.pgn")

    {:ok, game} = Chexx.PGN.parse!(pgn)
  end
end
