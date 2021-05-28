defmodule ChexxTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Chexx.Square
  alias Chexx.Board
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }

  import OK, only: [~>>: 2]

  doctest Chexx

  defp file do
    integer(1..8)
  end

  defp rank do
    integer(1..8)
  end

  defp square do
    {file(), rank()}
    |>StreamData.map(&Square.new/1)
  end

  defp square(within_file, within_rank) do
    {integer(within_file), integer(within_rank)}
    |> StreamData.map(&Square.new/1)
  end

  defp color do
    StreamData.member_of([:black, :white])
  end

  defp direction do
    member_of([
      :up,
      :up_right,
      :right,
      :down_right,
      :down,
      :down_left,
      :left,
      :up_left
    ])
  end

  describe "pawn moves" do
    property "can move a pawn up one square" do
      check all destination <- square(1..8, 2..7) do
        start_square = Square.down(destination)

        move = Square.to_algebraic(destination)

        {:ok, game} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Pawn{color: :white}, start_square)
          ~>> Chexx.play_board(:white)
          ~>> Chexx.ply(move)

        piece_at_dest = Board.piece_at(game.board, destination)

        assert piece_at_dest == %Pawn{color: :white}
      end
    end

    property "can move a black pawn down one square" do
      check all dest_square <- square(1..8, 2..7) do
        start_square = Square.up(dest_square)

        move = Square.to_algebraic(dest_square)

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Pawn{color: :black}, start_square)
          ~>> Chexx.play_board(:black)
          ~>> Chexx.ply(move)

        piece_at_dest = Board.piece_at(match.board, dest_square)

        assert piece_at_dest == %Pawn{color: :black}
      end
    end

    test "can move a white pawn up two squares if it is in the starting row" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e4")

      piece = Board.piece_at(match.board, :e, 4)

      assert piece == %Pawn{color: :white}
    end

    test "allows check notation when the king is in check" do
      {:ok, _match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Pawn{color: :white}, :d, 6)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("d7+")
    end

    test "can't give check notation if the king is not in check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Pawn{color: :white}, :d, 5)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("d6+")
    end

    test "expects notation when king is in check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Pawn{color: :white}, :d, 6)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("d7")
    end

    test "can move a black pawn down two squares if it is in the starting row" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 7)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece == %Pawn{color: :black}
    end

    test "can't move a white pawn up two squares if a piece is in the way" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 2)
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e4")
    end

    test "can't move a black pawn down two squares if a piece is in the way" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 7)
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 6)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("e5")
    end

    test "can move a piece when two pieces can share a destination, as black" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 6)
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 4)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece == %Pawn{color: :black}
    end

    test "can move a piece when two pieces can share a destination, as white" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 6)
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 4)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece == %Pawn{color: :white}
    end

    test "can't move the other player's pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 3)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("e4")
    end

    test "can't jump the other player's pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 3)
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 4)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e5")
    end

    test "can't move other pieces via pawn notation" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Bishop{color: :white}, :e, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e4")
    end

    test "can't move if there are no pieces that can be moved" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("e5")
    end

    test "pawn capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :f, 5)
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 4)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("fxe4")

      piece = Board.piece_at(match.board, :e, 4)

      assert piece == %Pawn{color: :black}
    end

    test "capture is required in a pawn capture" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("exd4")
    end

    test "white en passant capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :e, 7)
        ~>> Board.put_piece(%Pawn{color: :white}, :f, 5)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move("e5", "fxe6")

      white_pawn = Board.piece_at(match.board, :e, 6)
      assert white_pawn == %Pawn{color: :white}

      assert is_nil(Board.piece_at(match.board, :e, 5)), "Pawn was not captured in an en passant capture."
    end

    test "black en passant capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Pawn{color: :black}, :f, 4)
        ~>> Board.put_piece(%Pawn{color: :white}, :e, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move("e4", "fxe3")

      pawn = Board.piece_at(match.board, :e, 3)
      assert pawn == %Pawn{color: :black}

      assert is_nil(Board.piece_at(match.board, :e, 4)), "Pawn was not captured in an en passant capture."
    end

    test "pawn promotion" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Pawn{color: :white}, :c, 7)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("c8Q+")

      promoted_queen = Board.piece_at(match.board, :c, 8)

      assert promoted_queen == %Queen{color: :white}
    end
  end

  describe "king moves" do
    property "can move all directions" do
      check all color <- color(),
                direction <- direction() do
        start = Chexx.Square.new(:b, 2)
        destination = Chexx.Square.move_direction(start, direction, 1)
        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%King{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.ply("K#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %King{color: color}
      end
    end
  end

  defp max_distance(square, direction) do
    case direction do
      :up -> 8 - square.rank
      :up_right -> min(max_distance(square, :up), max_distance(square, :right))
      :right -> 8 - square.file
      :down_right -> min(max_distance(square, :down), max_distance(square, :right))
      :down -> square.rank - 1
      :down_left -> min(max_distance(square, :down), max_distance(square, :left))
      :left -> square.file - 1
      :up_left -> min(max_distance(square, :up), max_distance(square, :left))
    end
  end

  describe "rook moves" do
    property "can move up, down, left, or right, any distance" do
      check all color <- color(),
                start <- square(),
                direction <- member_of([:up, :right, :down, :left]),
                max_distance = max_distance(start, direction),
                max_distance > 0,
                distance <- integer(1..max_distance) do

        destination = Square.move_direction(start, direction, distance)

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Rook{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.ply("R#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Rook{color: color}
      end
    end

    test "rook can't jump other pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Board.put_piece(%Bishop{color: :white}, :h, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Rh3")
    end
  end

  describe "white kingside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")

      actual_king = Board.piece_at(match.board, :g, 1)
      assert actual_king == %King{color: :white}

      actual_rook = Board.piece_at(match.board, :f, 1)
      assert actual_rook == %Rook{color: :white}
    end

    test "can't castle if the king has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.plies(["Ke1", "Ke7", "0-0"])
    end

    test "can't castle if the rook has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.plies(["Rh1", "Ke7", "0-0"])
    end

    test "can't castle if rook isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if rook isn't a rook" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Bishop{color: :white}, :h, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if king isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if king isn't a king" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Queen{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if there's a piece in the king's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Board.put_piece(%Knight{color: :white}, :g, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if there's a piece in the rook's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Board.put_piece(%Bishop{color: :white}, :f, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :h, 1)
        ~>> Board.put_piece(%Rook{color: :black}, :f, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0")
    end
  end

  describe "black kingside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")

      actual_king = Board.piece_at(match.board, :g, 8)
      assert actual_king == %King{color: :black}

      actual_rook = Board.piece_at(match.board, :f, 8)
      assert actual_rook == %Rook{color: :black}
    end

    test "can't castle if rook isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if rook isn't a rook" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Bishop{color: :black}, :h, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if king isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if king isn't a king" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Queen{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if there's a piece in the king's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Board.put_piece(%Knight{color: :black}, :g, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if there's a piece in the rook's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Board.put_piece(%Bishop{color: :black}, :f, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end

    test "can't castle if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :h, 8)
        ~>> Board.put_piece(%Rook{color: :white}, :f, 6)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0")
    end
  end

  describe "white queenside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0-0")

      actual_king = Board.piece_at(match.board, :c, 1)
      assert actual_king == %King{color: :white}

      actual_rook = Board.piece_at(match.board, :d, 1)
      assert actual_rook == %Rook{color: :white}
    end

    test "can't castle if the king has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.plies(["Ke1", "Ke7", "0-0-0"])
    end

    test "can't castle if the rook has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.plies(["Ra1", "Ke7", "0-0-0"])
    end

    test "can't castle queenside if the intervening square is occupied" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
        ~>> Board.put_piece(%Knight{color: :white}, :b, 1)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0-0")
    end

    test "can't castle queenside if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :white}, :e, 1)
        ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
        ~>> Board.put_piece(%Rook{color: :black}, :d, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("0-0-0")
    end
  end

  describe "black queenside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :a, 8)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0-0")

      actual_king = Board.piece_at(match.board, :c, 8)
      assert actual_king == %King{color: :black}

      actual_rook = Board.piece_at(match.board, :d, 8)
      assert actual_rook == %Rook{color: :black}
    end

    test "can't castle queenside if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%King{color: :black}, :e, 8)
        ~>> Board.put_piece(%Rook{color: :black}, :a, 8)
        ~>> Board.put_piece(%Rook{color: :white}, :d, 6)
        ~>> Chexx.play_board(:black)
        ~>> Chexx.ply("0-0-0")
    end
  end

  describe "queen moves" do
    property "can move any direction, any distance" do
      check all color <- color(),
                start <- square(2..7, 2..7),
                direction <- direction(),
                max_distance = max_distance(start, direction),
                distance <- integer(1..max_distance) do

        destination = Square.move_direction(start, direction, distance)

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Queen{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.ply("Q#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Queen{color: color}
      end
    end

    test "can't traverse through pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Queen{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :white}, :b, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Qc3")
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Queen{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :black}, :b, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Qxb2")

      piece_at_dest = Board.piece_at(match.board, :b, 2)

      assert piece_at_dest == %Queen{color: :white}
    end
  end

  describe "bishop moves" do
    property "can move diagonally, any distance" do
      check all color <- color(),
                start <- square(2..7, 2..7),
                direction <- member_of([:up_right, :down_right, :down_left, :up_left]),
                max_distance = max_distance(start, direction),
                distance <- integer(1..max_distance) do

        destination = Square.move_direction(start, direction, distance)

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Bishop{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.ply("B#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Bishop{color: color}
      end
    end

    test "can't traverse through pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Bishop{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :white}, :b, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Bc3")
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Bishop{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :black}, :b, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Bxb2")

      piece_at_dest = Board.piece_at(match.board, :b, 2)

      assert piece_at_dest == %Bishop{color: :white}
    end
  end

  defp knight_moves_from(square) do
    [
      square |> Square.up(2) |> Square.right(),
      square |> Square.up(2) |> Square.left(),
      square |> Square.right(2) |> Square.up(),
      square |> Square.right(2) |> Square.down(),
      square |> Square.down(2) |> Square.right(),
      square |> Square.down(2) |> Square.left(),
      square |> Square.left(2) |> Square.up(),
      square |> Square.left(2) |> Square.down()
    ]
  end

  describe "knight moves" do
    property "can move any direction in the weird way knights do" do
      check all color <- color(),
                start <- square(3..6, 3..6),
                destination <- member_of(knight_moves_from(start)) do

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%Knight{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.ply("N#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Knight{color: color}
      end
    end

    test "can traverse through pieces" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Knight{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :white}, :a, 2)
        ~>> Board.put_piece(%Pawn{color: :white}, :a, 3)
        ~>> Board.put_piece(%Pawn{color: :white}, :b, 2)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Nb3")

      piece_at_dest = Board.piece_at(match.board, :b, 3)

      assert piece_at_dest == %Knight{color: :white}
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Knight{color: :white}, :a, 1)
        ~>> Board.put_piece(%Pawn{color: :black}, :b, 3)
        ~>> Chexx.play_board(:white)
        ~>> Chexx.ply("Nxb3")

      piece_at_dest = Board.piece_at(match.board, :b, 3)

      assert piece_at_dest == %Knight{color: :white}
    end
  end

  test "can't put your king into check" do
    {:error, :invalid_ply} =
      {:ok, Board.new()}
      ~>> Board.put_piece(%King{color: :white}, :a, 1)
      ~>> Board.put_piece(%Rook{color: :black}, :b, 2)
      ~>> Chexx.play_board(:white)
      ~>> Chexx.ply("Kb1")
  end

  test "black can't move on the first turn of a game" do
    {:error, :invalid_ply} =
      Chexx.start_game()
      |> Chexx.ply("c5")
  end

  test "Georg Rotlewi vs Akiba Rubinstein" do
    game = Chexx.start_game()
    {:ok, game} =
      Chexx.plies(game, [
        "d4", "d5",
        "Nf3", "e6",
        "e3", "c5",
        "c4", "Nc6",
        "Nc3", "Nf6",
        "dxc5", "Bxc5",
        "a3", "a6",
        "b4", "Bd6",
        "Bb2", "0-0",
        "Qd2", "Qe7",
        "Bd3", "dxc4",
        "Bxc4", "b5",
        "Bd3", "Rd8",
        "Qe2", "Bb7",
        "0-0", "Ne5",
        "Nxe5", "Bxe5",
        "f4", "Bc7",
        "e4", "Rac8",
        "e5", "Bb6+",
        "Kh1", "Ng4",
        "Be4", "Qh4",
        "g3", "Rxc3",
        "gxh4", "Rd2",
        "Qxd2", "Bxe4+",
        "Qg2", "Rh3"
      ])
    {:ok, game} = Chexx.resign(game)

    assert game.status == :black_wins
  end

  test "fool's mate" do
    {:ok, game} =
      Chexx.start_game()
      |> Chexx.plies([
          "f3", "e5",
          "g4", "Qh4#"
      ])

    assert game.status == :black_wins
  end

  test "three-piece mate" do
    {:ok, game} =
      {:ok, Board.new()}
      ~>> Board.put_piece(%King{color: :white}, :f, 5)
      ~>> Board.put_piece(%King{color: :black}, :h, 5)
      ~>> Board.put_piece(%Rook{color: :white}, :a, 1)
      ~>> Chexx.play_board(:white)
      ~>> Chexx.ply("Rh1#")

    assert game.status == :white_wins
  end

  test "Game of the Century" do
    game = Chexx.start_game()
    {:ok, game} =
      Chexx.moves(game, [
        "Nf3 Nf6",
        "c4 g6",
        "Nc3 Bg7",
        "d4 0-0",
        "Bf4 d5",
        "Qb3 dxc4",
        "Qxc4 c6",
        "e4 Nbd7",
        "Rd1 Nb6",
        "Qc5 Bg4",
        "Bg5 Na4",
        "Qa3 Nxc3",
        "bxc3 Nxe4",
        "Bxe7 Qb6",
        "Bc4 Nxc3",
        "Bc5 Rfe8+",
        "Kf1 Be6",
        "Bxb6 Bxc4+",
        "Kg1 Ne2+",
        "Kf1 Nxd4+",
        "Kg1 Ne2+",
        "Kf1 Nc3+",
        "Kg1 axb6",
        "Qb4 Ra4",
        "Qxb6 Nxd1",
        "h3 Rxa2",
        "Kh2 Nxf2",
        "Re1 Rxe1",
        "Qd8+ Bf8",
        "Nxe1 Bd5",
        "Nf3 Ne4",
        "Qb8 b5",
        "h4 h5",
        "Ne5 Kg7",
        "Kg1 Bc5+",
        "Kf1 Ng3+",
        "Ke1 Bb4+",
        "Kd1 Bb3+",
        "Kc1 Ne2+",
        "Kb1 Nc3+",
        "Kc1 Rc2#"
      ])

    assert game.status == :black_wins
  end
end
