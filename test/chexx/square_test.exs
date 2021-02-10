defmodule Chexx.SquareTest do
  use ExUnit.Case
  alias Chexx.Square
  doctest Chexx.Square

  describe "squares_between/2" do
    test "diagonals" do
      a = Square.new(:d, 8)
      b = Square.new(:h, 4)
      squares = Square.squares_between(a, b)

      assert Enum.count(squares) == 3
      assert Square.new(:e, 7) in squares
      assert Square.new(:f, 6) in squares
      assert Square.new(:g, 5) in squares
    end
  end
end
