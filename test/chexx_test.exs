defmodule ChexxTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Chexx

  defp file do
    member_of([
      :a, :b, :c, :d, :e, :f, :g, :h
    ])
  end

  defp rank do
    integer(1..8)
  end

  defp square do
    {file(), rank()}
  end

  defp piece_type do
    StreamData.member_of([:pawn, :rook, :knight, :bishop, :queen, :king])
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

  describe "put_piece" do
    property "a piece put on any square in an empty board can be fetched with piece_at" do
      check all square <- square(),
                color <- color(),
                piece <- piece_type() do
        piece_at_square =
          Chexx.new()
          |> Chexx.put_piece(piece, color, square)
          |> Chexx.piece_at(square)

        assert piece_at_square.type == piece
        assert piece_at_square.color == color
      end
    end

    property "piece_at returns nil when square is empty" do
      check all square <- square() do
        piece =
          Chexx.new()
          |> Chexx.piece_at(square)

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
          Chexx.new()
          |> Chexx.put_piece(piece1, color1, square)
          |> Chexx.put_piece(piece2, color2, square)
        end
      end
    end

    property "can't put a piece off the top boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                file <- file() do
        assert_raise RuntimeError, fn ->
          Chexx.new()
          |> Chexx.put_piece(piece, color, {file, 9})
        end
      end
    end

    property "can't put a piece off the right boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                rank <- rank() do
        assert_raise RuntimeError, fn ->
          Chexx.new()
          |> Chexx.put_piece(piece, color, {:i, rank})
        end
      end
    end

    property "can't put a piece off the bottom boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                file <- file() do
        assert_raise RuntimeError, fn ->
          Chexx.new()
          |> Chexx.put_piece(piece, color, {file, 0})
        end
      end
    end
  end

  describe "pawn moves" do
    property "can move a pawn up one square" do
      check all dest_square <- {file(), member_of(2..8)} do
        {dest_file, dest_rank} = dest_square
        start_square = Chexx.down(dest_square)

        move = "#{dest_file}#{dest_rank}"

        piece_at_dest =
          Chexx.new()
          |> Chexx.put_piece(:pawn, :white, start_square)
          |> Chexx.move(:white, move)
          |> Chexx.piece_at(dest_square)

        assert piece_at_dest.type == :pawn
        assert piece_at_dest.color == :white
      end
    end

    property "can move a black pawn down one square" do
      check all dest_square <- {file(), member_of(1..7)} do
        {dest_file, dest_rank} = dest_square
        start_square = Chexx.up(dest_square)

        move = "#{dest_file}#{dest_rank}"

        piece_at_dest =
          Chexx.new()
          |> Chexx.put_piece(:pawn, :black, start_square)
          |> Chexx.move(:black, move)
          |> Chexx.piece_at(dest_square)

        assert piece_at_dest.type == :pawn
        assert piece_at_dest.color == :black
      end
    end

    test "can move a white pawn up two squares if it is in the starting row" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :white, {:e, 2})
        |> Chexx.move(:white, "e4")
        |> Chexx.piece_at({:e, 4})

        assert piece.type == :pawn
        assert piece.color == :white
    end

    test "can move a black pawn down two squares if it is in the starting row" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 7})
        |> Chexx.move(:black, "e5")
        |> Chexx.piece_at({:e, 5})

        assert piece.type == :pawn
        assert piece.color == :black
    end

    test "can't move a white pawn up two squares if a piece is in the way" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:pawn, :white, {:e, 2})
        |> Chexx.put_piece(:pawn, :black, {:e, 3})
        |> Chexx.move(:white, "e4")
      end
    end

    test "can't move a black pawn down two squares if a piece is in the way" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 7})
        |> Chexx.put_piece(:pawn, :white, {:e, 6})
        |> Chexx.move(:white, "e5")
      end
    end

    test "can move a piece when two pieces can share a destination, as black" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 6})
        |> Chexx.put_piece(:pawn, :white, {:e, 4})
        |> Chexx.move(:black, "e5")
        |> Chexx.piece_at({:e, 5})

        assert piece.type == :pawn
        assert piece.color == :black
    end

    test "can move a piece when two pieces can share a destination, as white" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 6})
        |> Chexx.put_piece(:pawn, :white, {:e, 4})
        |> Chexx.move(:white, "e5")
        |> Chexx.piece_at({:e, 5})

        assert piece.type == :pawn
        assert piece.color == :white
    end

    test "can't move the other player's pieces" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:pawn, :white, {:e, 3})
        |> Chexx.move(:black, "e4")
      end
    end

    test "can't move other pieces via pawn notation" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:bishop, :white, {:e, 3})
        |> Chexx.move(:white, "e4")
      end
    end

    test "can't move if there are no pieces that can be moved" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.move(:black, "e5")
      end
    end

    test "pawn capture" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:f, 5})
        |> Chexx.put_piece(:pawn, :white, {:e, 4})
        |> Chexx.move(:black, "fxe4")
        |> Chexx.piece_at({:e, 4})

      assert piece.type == :pawn
      assert piece.color == :black
    end

    test "capture is required in a pawn capture" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:pawn, :white, {:e, 3})
        |> Chexx.move(:white, "exd4")
      end
    end

    test "white en passant capture" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 7})
        |> Chexx.put_piece(:pawn, :white, {:f, 5})
        |> Chexx.move(:black, "e5")
        |> Chexx.move(:white, "fxe6")


      white_pawn = Chexx.piece_at(board, {:e, 6})
      assert white_pawn.type == :pawn
      assert white_pawn.color == :white

      assert is_nil(Chexx.piece_at(board, {:e, 5})), "Pawn was not captured in an en passant capture."
    end

    test "black en passant capture" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:f, 4})
        |> Chexx.put_piece(:pawn, :white, {:e, 2})
        |> Chexx.move(:white, "e4")
        |> Chexx.move(:black, "fxe3")


      white_pawn = Chexx.piece_at(board, {:e, 3})
      assert white_pawn.type == :pawn
      assert white_pawn.color == :black

      assert is_nil(Chexx.piece_at(board, {:e, 4})), "Pawn was not captured in an en passant capture."
    end
  end

  describe "king moves" do
    property "can move all directions" do
      check all color <- color(),
                direction <- direction() do
        start = {:b, 2}
        {dest_file, dest_rank} = Chexx.move_direction(start, direction, 1)
        piece_at_dest =
          Chexx.new()
          |> Chexx.put_piece(:king, color, start)
          |> Chexx.move(color, "K#{dest_file}#{dest_rank}")
          |> Chexx.piece_at({dest_file, dest_rank})

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :king
      end
    end
  end

  defp max_distance({start_file, start_rank}, direction) do
    case direction do
      :up -> 8 - start_rank
      :right -> 8 - Chexx.file_to_number(start_file)
      :down -> start_rank - 1
      :left -> Chexx.file_to_number(start_file) - 1
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

        {dest_file, dest_rank} = Chexx.move_direction(start, direction, distance)

        piece_at_dest =
          Chexx.new()
          |> Chexx.put_piece(:rook, color, start)
          |> Chexx.move(color, "R#{dest_file}#{dest_rank}")
          |> Chexx.piece_at({dest_file, dest_rank})

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :rook
      end
    end
  end

  describe "white kingside castle" do
    test "succeeds when pieces are in the right place" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:rook, :white, {:h, 1})
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.move(:white, "0-0")

      actual_king = Chexx.piece_at(board, {:g, 1})
      assert actual_king.type == :king
      assert actual_king.color == :white

      actual_rook = Chexx.piece_at(board, {:f, 1})
      assert actual_rook.type == :rook
      assert actual_rook.color == :white
    end

    test "can't castle if rook isn't there" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.move(:white, "0-0")
      end
    end

    test "can't castle if rook isn't a rook" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.put_piece(:bishop, :white, {:h, 1})
        |> Chexx.move(:white, "0-0")
      end
    end

    test "can't castle if king isn't there" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :white, {:h, 1})
        |> Chexx.move(:white, "0-0")
      end
    end

    test "can't castle if king isn't a king" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:queen, :white, {:e, 1})
        |> Chexx.put_piece(:rook, :white, {:h, 1})
        |> Chexx.move(:white, "0-0")
      end
    end

    test "can't castle if there's a piece in the king's destination" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.put_piece(:rook, :white, {:h, 1})
        |> Chexx.put_piece(:knight, :white, {:g, 1})
        |> Chexx.move(:white, "0-0")
      end
    end

    test "can't castle if there's a piece in the rook's destination" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.put_piece(:rook, :white, {:h, 1})
        |> Chexx.put_piece(:bishop, :white, {:f, 1})
        |> Chexx.move(:white, "0-0")
      end
    end
  end

  describe "black kingside castle" do
    test "succeeds when pieces are in the right place" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:h, 8})
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.move(:black, "0-0")

      actual_king = Chexx.piece_at(board, {:g, 8})
      assert actual_king.type == :king
      assert actual_king.color == :black

      actual_rook = Chexx.piece_at(board, {:f, 8})
      assert actual_rook.type == :rook
      assert actual_rook.color == :black
    end

    test "can't castle if rook isn't there" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.move(:black, "0-0")
      end
    end

    test "can't castle if rook isn't a rook" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.put_piece(:bishop, :black, {:h, 8})
        |> Chexx.move(:black, "0-0")
      end
    end

    test "can't castle if king isn't there" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:h, 8})
        |> Chexx.move(:black, "0-0")
      end
    end

    test "can't castle if king isn't a king" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:queen, :black, {:e, 8})
        |> Chexx.put_piece(:rook, :black, {:h, 8})
        |> Chexx.move(:black, "0-0")
      end
    end

    test "can't castle if there's a piece in the king's destination" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.put_piece(:rook, :black, {:h, 8})
        |> Chexx.put_piece(:knight, :black, {:g, 8})
        |> Chexx.move(:black, "0-0")
      end
    end

    test "can't castle if there's a piece in the rook's destination" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.put_piece(:rook, :black, {:h, 8})
        |> Chexx.put_piece(:bishop, :black, {:f, 8})
        |> Chexx.move(:black, "0-0")
      end
    end
  end

  describe "white queenside castle" do
    test "succeeds when pieces are in the right place" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.put_piece(:rook, :white, {:a, 1})
        |> Chexx.move(:white, "0-0-0")

      actual_king = Chexx.piece_at(board, {:c, 1})
      assert actual_king.type == :king
      assert actual_king.color == :white

      actual_rook = Chexx.piece_at(board, {:d, 1})
      assert actual_rook.type == :rook
      assert actual_rook.color == :white
    end

    test "can't castle queenside if the intervening square is occupied" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:king, :white, {:e, 1})
        |> Chexx.put_piece(:rook, :white, {:a, 1})
        |> Chexx.put_piece(:knight, :white, {:b, 1})
        |> Chexx.move(:white, "0-0-0")
      end
    end
  end

  describe "black queenside castle" do
    test "succeeds when pieces are in the right place" do
      board =
        Chexx.new()
        |> Chexx.put_piece(:king, :black, {:e, 8})
        |> Chexx.put_piece(:rook, :black, {:a, 8})
        |> Chexx.move(:black, "0-0-0")

      actual_king = Chexx.piece_at(board, {:c, 8})
      assert actual_king.type == :king
      assert actual_king.color == :black

      actual_rook = Chexx.piece_at(board, {:d, 8})
      assert actual_rook.type == :rook
      assert actual_rook.color == :black
    end
  end
end
