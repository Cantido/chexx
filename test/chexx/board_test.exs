defmodule Chexx.BoardTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Chexx.Square
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }
  alias Chexx.Board
  import OK, only: [~>: 2, ~>>: 2]

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

  defp piece do
    {piece_type(), color()}
    |> StreamData.map(fn {piece, color} ->
      case piece do
        :king -> %King{color: color}
        :queen -> %Queen{color: color}
        :rook -> %Rook{color: color}
        :knight -> %Knight{color: color}
        :bishop -> %Bishop{color: color}
        :pawn -> %Pawn{color: color}
      end
    end)
  end

  describe "put_piece" do
    property "a piece put on any square in an empty board can be fetched with piece_at" do
      check all square <- square(),
                piece <- piece() do
        {:ok, piece_at_square} =
          {:ok, Board.new()}
          ~>> Board.put_piece(piece, square)
          ~> Board.piece_at(square)

        assert piece_at_square == piece
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
                piece1 <- piece(),
                piece2 <- piece() do
        {:error, _msg} =
          {:ok, Board.new()}
          ~>> Board.put_piece(piece1, square)
          ~>> Board.put_piece(piece2, square)
      end
    end

    property "can't put a piece off the top boundary of the board" do
      check all piece <- piece(),
                file <- file() do
        {:error, _msg} =
          Board.new()
          |> Board.put_piece(piece, Square.new(file, 9))
      end
    end

    property "can't put a piece off the right boundary of the board" do
      check all piece <- piece(),
                rank <- rank() do
        {:error, _msg} =
          Board.new()
          |> Board.put_piece(piece, Square.new(9, rank))
      end
    end

    property "can't put a piece off the bottom boundary of the board" do
      check all piece <- piece(),
                file <- file() do
        {:error, _msg} =
          Board.new()
          |> Board.put_piece(piece, Square.new({file, 0}))
      end
    end
  end
end
