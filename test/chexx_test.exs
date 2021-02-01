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
    member_of(1..8)
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
          |> Chexx.put_piece(color, piece, {file, 9})
        end
      end
    end

    property "can't put a piece off the right boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                rank <- rank() do
        assert_raise RuntimeError, fn ->
          Chexx.new()
          |> Chexx.put_piece(color, piece, {:i, rank})
        end
      end
    end

    property "can't put a piece off the bottom boundary of the board" do
      check all color <- color(),
                piece <- piece_type(),
                file <- file() do
        assert_raise RuntimeError, fn ->
          Chexx.new()
          |> Chexx.put_piece(color, piece, {file, 0})
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
end
