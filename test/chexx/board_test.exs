defmodule Chexx.BoardTest do
  use ExUnit.Case
  use ExUnitProperties
  alias Chexx.Square
  alias Chexx.Board
  
  doctest Chexx.Board

  defp file do
    integer(1..8)
  end

  defp rank do
    integer(1..8)
  end

  defp square do
    {file(), rank()}
    |> StreamData.map(&Square.new/1)
  end

  defp piece_type do
    StreamData.member_of([:pawn, :rook, :knight, :bishop, :queen, :king])
  end

  defp color do
    StreamData.member_of([:black, :white])
  end

  describe "put_piece" do
    property "a piece put on any square in an empty board can be fetched with piece_at" do
      check all square <- square(),
                color <- color(),
                piece <- piece_type() do
        piece_at_square =
          Board.new()
          |> Board.put_piece(piece, color, square)
          |> Board.piece_at(square)

        assert piece_at_square.type == piece
        assert piece_at_square.color == color
      end
    end

    property "piece_at returns nil when square is empty" do
      check all square <- square() do
        piece =
          Board.new()
          |> Board.piece_at(square)

        assert piece == nil
      end
    end

    property "can't put a piece on the same square twice" do
      check all square <- square(),
                color1 <- color(),
                color2 <- color(),
                piece1 <- piece_type(),
                piece2 <- piece_type() do
        assert_raise RuntimeError, fn ->
          Board.new()
          |> Board.put_piece(piece1, color1, square)
          |> Board.put_piece(piece2, color2, square)
        end
      end
    end

    property "can't put a piece off the top boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                file <- file() do
        assert_raise RuntimeError, fn ->
          Board.new()
          |> Board.put_piece(piece, color, Square.new(file, 9))
        end
      end
    end

    property "can't put a piece off the right boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                rank <- rank() do
        assert_raise RuntimeError, fn ->
          Board.new()
          |> Board.put_piece(piece, color, Square.new(9, rank))
        end
      end
    end

    property "can't put a piece off the bottom boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                file <- file() do
        assert_raise RuntimeError, fn ->
          Board.new()
          |> Board.put_piece(piece, color, Square.new({file, 0}))
        end
      end
    end
  end
end
