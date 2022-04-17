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

  import Chexx.Square, only: [sigil_q: 2]
  import Chexx.AlgebraicNotation, only: [sigil_a: 2]
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
          ~>> Board.put_piece(Pawn.white(), start_square)
          ~>> Chexx.play_board(:white)
          ~>> Chexx.move(~a[#{move}])

        piece_at_dest = Board.piece_at(game.board, destination)

        assert piece_at_dest == Pawn.white()
      end
    end

    property "can move a black pawn down one square" do
      check all dest_square <- square(1..8, 2..7) do
        start_square = Square.up(dest_square)

        move = Square.to_algebraic(dest_square)

        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(Pawn.black(), start_square)
          ~>> Chexx.play_board(:black)
          ~>> Chexx.move(~a[#{move}])

        piece_at_dest = Board.piece_at(match.board, dest_square)

        assert piece_at_dest == Pawn.black()
      end
    end

    test "can move a white pawn up two squares if it is in the starting row" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.white(), ~q[e2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e4])

      piece = Board.piece_at(match.board, ~q[e4])

      assert piece == Pawn.white()
    end

    test "allows check notation when the king is in check" do
      {:ok, _match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Pawn.white(), ~q[d6])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[d7+])
    end

    test "can't give check notation if the king is not in check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Pawn.white(), ~q[d5])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[d6+])
    end

    test "expects notation when king is in check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Pawn.white(), ~q[d6])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[d7])
    end

    test "can move a black pawn down two squares if it is in the starting row" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[e7])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[e5])

      piece = Board.piece_at(match.board, ~q[e5])

      assert piece == Pawn.black()
    end

    test "can't move a white pawn up two squares if a piece is in the way" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.white(), ~q[e2])
        ~>> Board.put_piece(Pawn.black(), ~q[e3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e4])
    end

    test "can't move a black pawn down two squares if a piece is in the way" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[e7])
        ~>> Board.put_piece(Pawn.white(), ~q[e6])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[e5])
    end

    test "can move a piece when two pieces can share a destination, as black" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[e6])
        ~>> Board.put_piece(Pawn.white(), ~q[e4])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[e5])

      piece = Board.piece_at(match.board, ~q[e5])

      assert piece == Pawn.black()
    end

    test "can move a piece when two pieces can share a destination, as white" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[e6])
        ~>> Board.put_piece(Pawn.white(), ~q[e4])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e5])

      piece = Board.piece_at(match.board, ~q[e5])

      assert piece == Pawn.white()
    end

    test "can't move the other player's pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.white(), ~q[e3])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[e4])
    end

    test "can't jump the other player's pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.white(), ~q[e3])
        ~>> Board.put_piece(Pawn.black(), ~q[e4])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e5])
    end

    test "can't move other pieces via pawn notation" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Bishop.white(), ~q[e3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e4])
    end

    test "can't move if there are no pieces that can be moved" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[e5])
    end

    test "pawn capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[f5])
        ~>> Board.put_piece(Pawn.white(), ~q[e4])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[fxe4])

      piece = Board.piece_at(match.board, ~q[e4])

      assert piece == Pawn.black()
    end

    test "capture is required in a pawn capture" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.white(), ~q[e3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[exd4])
    end

    test "white en passant capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[e7])
        ~>> Board.put_piece(Pawn.white(), ~q[f5])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move([~a[e5], ~a[fxe6]])

      white_pawn = Board.piece_at(match.board, ~q[e6])
      assert white_pawn == Pawn.white()

      assert is_nil(Board.piece_at(match.board, ~q[e5])), "Pawn was not captured in an en passant capture."
    end

    test "black en passant capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Pawn.black(), ~q[f4])
        ~>> Board.put_piece(Pawn.white(), ~q[e2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move([~a[e4], ~a[fxe3]])

      pawn = Board.piece_at(match.board, ~q[e3])
      assert pawn == Pawn.black()

      assert is_nil(Board.piece_at(match.board, ~q[e4])), "Pawn was not captured in an en passant capture."
    end

    test "pawn promotion" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Pawn.white(), ~q[c7])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[c8Q+])

      promoted_queen = Board.piece_at(match.board, ~q[c8])

      assert promoted_queen == Queen.white()
    end
  end

  describe "king moves" do
    property "can move all directions" do
      check all color <- color(),
                direction <- direction() do
        start = Chexx.Square.new(~q[b2])
        destination = Chexx.Square.move_direction(start, direction, 1)
        {:ok, match} =
          {:ok, Board.new()}
          ~>> Board.put_piece(%King{color: color}, start)
          ~>> Chexx.play_board(color)
          ~>> Chexx.move(~a[K#{Square.to_algebraic(destination)}])

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
          ~>> Chexx.move(~a[R#{Square.to_algebraic(destination)}])

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Rook{color: color}
      end
    end

    test "rook can't jump other pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(Bishop.white(), ~q[h2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Rh3])
    end
  end

  describe "white kingside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])

      actual_king = Board.piece_at(match.board, ~q[g1])
      assert actual_king == King.white()

      actual_rook = Board.piece_at(match.board, ~q[f1])
      assert actual_rook == Rook.white()
    end

    test "can't castle if the king has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move([~a[Ke1], ~a[Ke7], ~a[0-0]])
    end

    test "can't castle if the rook has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move([~a[Rh1], ~a[Ke7], ~a[0-0]])
    end

    test "can't castle if rook isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if rook isn't a rook" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Bishop.white(), ~q[h1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if king isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if king isn't a king" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Queen.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if there's a piece in the king's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(%Knight{color: :white}, ~q[g1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if there's a piece in the rook's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(Bishop.white(), ~q[f1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(Rook.black(), ~q[f3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle out of check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[h1])
        ~>> Board.put_piece(Rook.black(), ~q[e3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end
  end

  describe "black kingside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])

      actual_king = Board.piece_at(match.board, ~q[g8])
      assert actual_king == King.black()

      actual_rook = Board.piece_at(match.board, ~q[f8])
      assert actual_rook == Rook.black()
    end

    test "can't castle if rook isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if rook isn't a rook" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Bishop.black(), ~q[h8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if king isn't there" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if king isn't a king" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Queen.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if there's a piece in the king's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Board.put_piece(%Knight{color: :black}, ~q[g8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if there's a piece in the rook's destination" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Board.put_piece(Bishop.black(), ~q[f8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Board.put_piece(Rook.white(), ~q[f6])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0])
    end

    test "can't castle out of check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[h8])
        ~>> Board.put_piece(Rook.white(), ~q[e6])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0])
    end
  end

  describe "white queenside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0-0])

      actual_king = Board.piece_at(match.board, ~q[c1])
      assert actual_king == King.white()

      actual_rook = Board.piece_at(match.board, ~q[d1])
      assert actual_rook == Rook.white()
    end

    test "can't castle if the king has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move([~a[Ke1], ~a[Ke7], ~a[0-0-0]])
    end

    test "can't castle if the rook has moved before" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move([~a[Ra1], ~a[Ke7], ~a[0-0-0]])
    end

    test "can't castle queenside if the intervening square is occupied" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Board.put_piece(%Knight{color: :white}, ~q[b1])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0-0])
    end

    test "can't castle queenside if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Board.put_piece(Rook.black(), ~q[d3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0-0])
    end

    test "can't castle out of check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.white(), ~q[e1])
        ~>> Board.put_piece(Rook.white(), ~q[a1])
        ~>> Board.put_piece(Rook.black(), ~q[e3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[0-0-0])
    end
  end

  describe "black queenside castle" do
    test "succeeds when pieces are in the right place" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[a8])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0-0])

      actual_king = Board.piece_at(match.board, ~q[c8])
      assert actual_king == King.black()

      actual_rook = Board.piece_at(match.board, ~q[d8])
      assert actual_rook == Rook.black()
    end

    test "can't castle queenside if a piece is attacking one of the king's traversed squares" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[a8])
        ~>> Board.put_piece(Rook.white(), ~q[d6])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0-0])
    end

    test "can't castle out of check" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(King.black(), ~q[e8])
        ~>> Board.put_piece(Rook.black(), ~q[a8])
        ~>> Board.put_piece(Rook.white(), ~q[e6])
        ~>> Chexx.play_board(:black)
        ~>> Chexx.move(~a[0-0-0])
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
          ~>> Chexx.move(~a[Q#{Square.to_algebraic(destination)}])

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Queen{color: color}
      end
    end

    test "can't traverse through pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Queen.white(), ~q[a1])
        ~>> Board.put_piece(Pawn.white(), ~q[b2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Qc3])
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Queen.white(), ~q[a1])
        ~>> Board.put_piece(Pawn.black(), ~q[b2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Qxb2])

      piece_at_dest = Board.piece_at(match.board, ~q[b2])

      assert piece_at_dest == Queen.white()
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
          ~>> Chexx.move(~a[B#{Square.to_algebraic(destination)}])

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Bishop{color: color}
      end
    end

    test "can't traverse through pieces" do
      {:error, :invalid_ply} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Bishop.white(), ~q[a1])
        ~>> Board.put_piece(Pawn.white(), ~q[b2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Bc3])
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(Bishop.white(), ~q[a1])
        ~>> Board.put_piece(Pawn.black(), ~q[b2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Bxb2])

      piece_at_dest = Board.piece_at(match.board, ~q[b2])

      assert piece_at_dest == Bishop.white()
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
          ~>> Chexx.move(~a[N#{Square.to_algebraic(destination)}])

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest == %Knight{color: color}
      end
    end

    test "can traverse through pieces" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Knight{color: :white}, ~q[a1])
        ~>> Board.put_piece(Pawn.white(), ~q[a2])
        ~>> Board.put_piece(Pawn.white(), ~q[a3])
        ~>> Board.put_piece(Pawn.white(), ~q[b2])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Nb3])

      piece_at_dest = Board.piece_at(match.board, ~q[b3])

      assert piece_at_dest == %Knight{color: :white}
    end

    test "can capture" do
      {:ok, match} =
        {:ok, Board.new()}
        ~>> Board.put_piece(%Knight{color: :white}, ~q[a1])
        ~>> Board.put_piece(Pawn.black(), ~q[b3])
        ~>> Chexx.play_board(:white)
        ~>> Chexx.move(~a[Nxb3])

      piece_at_dest = Board.piece_at(match.board, ~q[b3])

      assert piece_at_dest == %Knight{color: :white}
    end
  end

  test "can't put your king into check" do
    {:error, :invalid_ply} =
      {:ok, Board.new()}
      ~>> Board.put_piece(King.white(), ~q[a1])
      ~>> Board.put_piece(Rook.black(), ~q[b2])
      ~>> Chexx.play_board(:white)
      ~>> Chexx.move(~a[Kb1])
  end

  test "black can't move on the first turn of a game" do
    {:error, :invalid_ply} =
      Chexx.start_game()
      |> Chexx.move(~a[c5])
  end

  test "Georg Rotlewi vs Akiba Rubinstein" do
    game = Chexx.start_game()
    {:ok, game} =
      Chexx.move(game, [
        ~a[d4], ~a[d5],
        ~a[Nf3], ~a[e6],
        ~a[e3], ~a[c5],
        ~a[c4], ~a[Nc6],
        ~a[Nc3], ~a[Nf6],
        ~a[dxc5], ~a[Bxc5],
        ~a[a3], ~a[a6],
        ~a[b4], ~a[Bd6],
        ~a[Bb2], ~a[0-0],
        ~a[Qd2], ~a[Qe7],
        ~a[Bd3], ~a[dxc4],
        ~a[Bxc4], ~a[b5],
        ~a[Bd3], ~a[Rd8],
        ~a[Qe2], ~a[Bb7],
        ~a[0-0], ~a[Ne5],
        ~a[Nxe5], ~a[Bxe5],
        ~a[f4], ~a[Bc7],
        ~a[e4], ~a[Rac8],
        ~a[e5], ~a[Bb6+],
        ~a[Kh1], ~a[Ng4],
        ~a[Be4], ~a[Qh4],
        ~a[g3], ~a[Rxc3],
        ~a[gxh4], ~a[Rd2],
        ~a[Qxd2], ~a[Bxe4+],
        ~a[Qg2], ~a[Rh3]
      ])
    {:ok, game} = Chexx.resign(game)

    assert game.status == :black_wins
  end

  test "fool's mate" do
    {:ok, game} =
      Chexx.start_game()
      |> Chexx.move([
          ~a[f3], ~a[e5],
          ~a[g4], ~a[Qh4#]
      ])

    assert game.status == :black_wins
  end

  test "three-piece mate" do
    {:ok, game} =
      {:ok, Board.new()}
      ~>> Board.put_piece(King.white(), ~q[f5])
      ~>> Board.put_piece(King.black(), ~q[h5])
      ~>> Board.put_piece(Rook.white(), ~q[a1])
      ~>> Chexx.play_board(:white)
      ~>> Chexx.move(~a[Rh1#])

    assert game.status == :white_wins
  end

  test "Game of the Century" do
    game = Chexx.start_game()
    {:ok, game} =
      Chexx.move(game, [
        ~a[Nf3], ~a[Nf6],
        ~a[c4], ~a[g6],
        ~a[Nc3], ~a[Bg7],
        ~a[d4], ~a[0-0],
        ~a[Bf4], ~a[d5],
        ~a[Qb3], ~a[dxc4],
        ~a[Qxc4], ~a[c6],
        ~a[e4], ~a[Nbd7],
        ~a[Rd1], ~a[Nb6],
        ~a[Qc5], ~a[Bg4],
        ~a[Bg5], ~a[Na4],
        ~a[Qa3], ~a[Nxc3],
        ~a[bxc3], ~a[Nxe4],
        ~a[Bxe7], ~a[Qb6],
        ~a[Bc4], ~a[Nxc3],
        ~a[Bc5], ~a[Rfe8+],
        ~a[Kf1], ~a[Be6],
        ~a[Bxb6], ~a[Bxc4+],
        ~a[Kg1], ~a[Ne2+],
        ~a[Kf1], ~a[Nxd4+],
        ~a[Kg1], ~a[Ne2+],
        ~a[Kf1], ~a[Nc3+],
        ~a[Kg1], ~a[axb6],
        ~a[Qb4], ~a[Ra4],
        ~a[Qxb6], ~a[Nxd1],
        ~a[h3], ~a[Rxa2],
        ~a[Kh2], ~a[Nxf2],
        ~a[Re1], ~a[Rxe1],
        ~a[Qd8+], ~a[Bf8],
        ~a[Nxe1], ~a[Bd5],
        ~a[Nf3], ~a[Ne4],
        ~a[Qb8], ~a[b5],
        ~a[h4], ~a[h5],
        ~a[Ne5], ~a[Kg7],
        ~a[Kg1], ~a[Bc5+],
        ~a[Kf1], ~a[Ng3+],
        ~a[Ke1], ~a[Bb4+],
        ~a[Kd1], ~a[Bb3+],
        ~a[Kc1], ~a[Ne2+],
        ~a[Kb1], ~a[Nc3+],
        ~a[Kc1], ~a[Rc2#]
      ])

    assert game.status == :black_wins
  end
end
