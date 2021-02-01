defmodule ChexxTest do
  use ExUnit.Case
  doctest Chexx

  describe "put_piece" do
    test "put a piece at a square" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:a, 8})
        |> Chexx.piece_at({:a, 8})

      assert piece.type == :rook
      assert piece.color == :black
    end

    test "piece_at returns nil when square is empty" do
      piece =
        Chexx.new()
        |> Chexx.piece_at({:a, 8})

      assert piece == nil
    end

    test "can't put a piece on the same square twice" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:a, 8})
        |> Chexx.put_piece(:rook, :black, {:a, 8})
      end
    end

    test "can't put a piece off the top boundary of the board" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:a, 9})
      end
    end

    test "can't put a piece off the right boundary of the board" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:i, 8})
      end
    end

    test "can't put a piece off the bottom boundary of the board" do
      assert_raise RuntimeError, fn ->
        Chexx.new()
        |> Chexx.put_piece(:rook, :black, {:a, 0})
      end
    end
  end

  describe "pawn moves" do
    test "can move a white pawn up one square" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :white, {:e, 3})
        |> Chexx.move(:white, "e4")
        |> Chexx.piece_at({:e, 4})

        assert piece.type == :pawn
        assert piece.color == :white
    end

    test "can move a black pawn down one square" do
      piece =
        Chexx.new()
        |> Chexx.put_piece(:pawn, :black, {:e, 6})
        |> Chexx.move(:black, "e5")
        |> Chexx.piece_at({:e, 5})

        assert piece.type == :pawn
        assert piece.color == :black
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
