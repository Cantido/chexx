defmodule Chexx.PGN do
  alias Chexx.PGN.Parser

  def parse!(pgn) do
    Parser.parse!(pgn)
  end
end
