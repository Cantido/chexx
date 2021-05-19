defmodule ChexxTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Chexx.Square
  alias Chexx.Board
  alias Chexx.Match

  doctest Chexx

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

        game =
          Board.new()
          |> Board.put_piece(:pawn, :white, start_square)
          |> Chexx.play_board(:white)
          |> Chexx.move(move)

        piece_at_dest = Board.piece_at(game.board, destination)

        assert piece_at_dest.type == :pawn
        assert piece_at_dest.color == :white
      end
    end

    property "can move a black pawn down one square" do
      check all dest_square <- square(1..8, 2..7) do
        start_square = Square.up(dest_square)

        move = Square.to_algebraic(dest_square)

        match =
          Board.new()
          |> Board.put_piece(:pawn, :black, start_square)
          |> Chexx.play_board(:black)
          |> Chexx.move(move)

        piece_at_dest = Board.piece_at(match.board, dest_square)

        assert piece_at_dest.type == :pawn
        assert piece_at_dest.color == :black
      end
    end

    test "can move a white pawn up two squares if it is in the starting row" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :white, :e, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("e4")

      piece = Board.piece_at(match.board, :e, 4)

      assert piece.type == :pawn
      assert piece.color == :white
    end

    test "allows check notation when the king is in check" do
      Board.new()
      |> Board.put_piece(:king, :black, :e, 8)
      |> Board.put_piece(:pawn, :white, :d, 6)
      |> Chexx.play_board(:white)
      |> Chexx.move("d7+")
    end

    test "can't give check notation if the king is not in check" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:pawn, :white, :d, 5)
        |> Chexx.play_board(:white)
        |> Chexx.move("d6+")
      end
    end

    test "expects notation when king is in check" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:pawn, :white, :d, 6)
        |> Chexx.play_board(:white)
        |> Chexx.move("d7")
      end
    end

    test "can move a black pawn down two squares if it is in the starting row" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :e, 7)
        |> Chexx.play_board(:black)
        |> Chexx.move("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece.type == :pawn
      assert piece.color == :black
    end

    test "can't move a white pawn up two squares if a piece is in the way" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:pawn, :white, :e, 2)
        |> Board.put_piece(:pawn, :black, :e, 3)
        |> Chexx.play_board(:white)
        |> Chexx.move("e4")
      end
    end

    test "can't move a black pawn down two squares if a piece is in the way" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:pawn, :black, :e, 7)
        |> Board.put_piece(:pawn, :white, :e, 6)
        |> Chexx.play_board(:black)
        |> Chexx.move("e5")
      end
    end

    test "can move a piece when two pieces can share a destination, as black" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :e, 6)
        |> Board.put_piece(:pawn, :white, :e, 4)
        |> Chexx.play_board(:black)
        |> Chexx.move("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece.type == :pawn
      assert piece.color == :black
    end

    test "can move a piece when two pieces can share a destination, as white" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :e, 6)
        |> Board.put_piece(:pawn, :white, :e, 4)
        |> Chexx.play_board(:white)
        |> Chexx.move("e5")

      piece = Board.piece_at(match.board, :e, 5)

      assert piece.type == :pawn
      assert piece.color == :white
    end

    test "can't move the other player's pieces" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:pawn, :white, :e, 3)
        |> Chexx.play_board(:black)
        |> Chexx.move("e4")
      end
    end

    test "can't jump the other player's pieces" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:pawn, :white, :e, 3)
        |> Board.put_piece(:pawn, :black, :e, 4)
        |> Chexx.play_board(:white)
        |> Chexx.move("e5")
      end
    end

    test "can't move other pieces via pawn notation" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:bishop, :white, :e, 3)
        |> Chexx.play_board(:white)
        |> Chexx.move("e4")
      end
    end

    test "can't move if there are no pieces that can be moved" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Chexx.play_board(:white)
        |> Chexx.move("e5")
      end
    end

    test "pawn capture" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :f, 5)
        |> Board.put_piece(:pawn, :white, :e, 4)
        |> Chexx.play_board(:black)
        |> Chexx.move("fxe4")

      piece = Board.piece_at(match.board, :e, 4)

      assert piece.type == :pawn
      assert piece.color == :black
    end

    test "capture is required in a pawn capture" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:pawn, :white, :e, 3)
        |> Chexx.play_board(:white)
        |> Chexx.move("exd4")
      end
    end

    test "white en passant capture" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :e, 7)
        |> Board.put_piece(:pawn, :white, :f, 5)
        |> Chexx.play_board(:black)
        |> Chexx.move("e5")
        |> Chexx.move("fxe6")

      white_pawn = Board.piece_at(match.board, :e, 6)
      assert white_pawn.type == :pawn
      assert white_pawn.color == :white

      assert is_nil(Board.piece_at(match.board, :e, 5)), "Pawn was not captured in an en passant capture."
    end

    test "black en passant capture" do
      match =
        Board.new()
        |> Board.put_piece(:pawn, :black, :f, 4)
        |> Board.put_piece(:pawn, :white, :e, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("e4")
        |> Chexx.move("fxe3")

      white_pawn = Board.piece_at(match.board, :e, 3)
      assert white_pawn.type == :pawn
      assert white_pawn.color == :black

      assert is_nil(Board.piece_at(match.board, :e, 4)), "Pawn was not captured in an en passant capture."
    end

    test "pawn promotion" do
      match =
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:pawn, :white, :c, 7)
        |> Chexx.play_board(:white)
        |> Chexx.move("c8Q+")

      promoted_queen = Board.piece_at(match.board, :c, 8)

      assert promoted_queen.type == :queen
      assert promoted_queen.color == :white
    end
  end

  describe "king moves" do
    property "can move all directions" do
      check all color <- color(),
                direction <- direction() do
        start = Chexx.Square.new(:b, 2)
        destination = Chexx.Square.move_direction(start, direction, 1)
        match =
          Board.new()
          |> Board.put_piece(:king, color, start)
          |> Chexx.play_board(color)
          |> Chexx.move("K#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :king
      end
    end
  end

  defp max_distance(square, direction) do
    {start_file, start_rank} = Square.coords(square)
    case direction do
      :up -> 8 - start_rank
      :up_right -> min(max_distance(square, :up), max_distance(square, :right))
      :right -> 8 - start_file
      :down_right -> min(max_distance(square, :down), max_distance(square, :right))
      :down -> start_rank - 1
      :down_left -> min(max_distance(square, :down), max_distance(square, :left))
      :left -> start_file - 1
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

        match =
          Board.new()
          |> Board.put_piece(:rook, color, start)
          |> Chexx.play_board(color)
          |> Chexx.move("R#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :rook
      end
    end

    test "rook can't jump other pieces" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Board.put_piece(:bishop, :white, :h, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Rh3")
      end
    end
  end

  describe "white kingside castle" do
    test "succeeds when pieces are in the right place" do
      match =
        Board.new()
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Board.put_piece(:king, :white, :e, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")

      actual_king = Board.piece_at(match.board, :g, 1)
      assert actual_king.type == :king
      assert actual_king.color == :white

      actual_rook = Board.piece_at(match.board, :f, 1)
      assert actual_rook.type == :rook
      assert actual_rook.color == :white
    end

    test "can't castle if the king has moved before" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("Ke1")
        |> Chexx.move("Ke7")
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if the rook has moved before" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("Rh1")
        |> Chexx.move("Ke7")
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if rook isn't there" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if rook isn't a rook" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:bishop, :white, :h, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if king isn't there" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if king isn't a king" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:queen, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if there's a piece in the king's destination" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Board.put_piece(:knight, :white, :g, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if there's a piece in the rook's destination" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :h, 1)
        |> Board.put_piece(:bishop, :white, :f, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0")
      end
    end
  end

  describe "black kingside castle" do
    test "succeeds when pieces are in the right place" do
      match =
        Board.new()
        |> Board.put_piece(:rook, :black, :h, 8)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")

      actual_king = Board.piece_at(match.board, :g, 8)
      assert actual_king.type == :king
      assert actual_king.color == :black

      actual_rook = Board.piece_at(match.board, :f, 8)
      assert actual_rook.type == :rook
      assert actual_rook.color == :black
    end

    test "can't castle if rook isn't there" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if rook isn't a rook" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:bishop, :black, :h, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if king isn't there" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:rook, :black, :h, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if king isn't a king" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:queen, :black, :e, 8)
        |> Board.put_piece(:rook, :black, :h, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if there's a piece in the king's destination" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:rook, :black, :h, 8)
        |> Board.put_piece(:knight, :black, :g, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end

    test "can't castle if there's a piece in the rook's destination" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:rook, :black, :h, 8)
        |> Board.put_piece(:bishop, :black, :f, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0")
      end
    end
  end

  describe "white queenside castle" do
    test "succeeds when pieces are in the right place" do
      match =
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :a, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0-0")

      actual_king = Board.piece_at(match.board, :c, 1)
      assert actual_king.type == :king
      assert actual_king.color == :white

      actual_rook = Board.piece_at(match.board, :d, 1)
      assert actual_rook.type == :rook
      assert actual_rook.color == :white
    end

    test "can't castle if the king has moved before" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :a, 1)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Chexx.play_board(:white)
        |> Chexx.move("Ke1")
        |> Chexx.move("Ke7")
        |> Chexx.move("0-0-0")
      end
    end

    test "can't castle if the rook has moved before" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :a, 1)
        |> Board.put_piece(:king, :black, :e, 8)
        |> Chexx.play_board(:white)
        |> Chexx.move("Ra1")
        |> Chexx.move("Ke7")
        |> Chexx.move("0-0-0")
      end
    end

    test "can't castle queenside if the intervening square is occupied" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:king, :white, :e, 1)
        |> Board.put_piece(:rook, :white, :a, 1)
        |> Board.put_piece(:knight, :white, :b, 1)
        |> Chexx.play_board(:white)
        |> Chexx.move("0-0-0")
      end
    end
  end

  describe "black queenside castle" do
    test "succeeds when pieces are in the right place" do
      match =
        Board.new()
        |> Board.put_piece(:king, :black, :e, 8)
        |> Board.put_piece(:rook, :black, :a, 8)
        |> Chexx.play_board(:black)
        |> Chexx.move("0-0-0")

      actual_king = Board.piece_at(match.board, :c, 8)
      assert actual_king.type == :king
      assert actual_king.color == :black

      actual_rook = Board.piece_at(match.board, :d, 8)
      assert actual_rook.type == :rook
      assert actual_rook.color == :black
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

        match =
          Board.new()
          |> Board.put_piece(:queen, color, start)
          |> Chexx.play_board(color)
          |> Chexx.move("Q#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :queen
      end
    end

    test "can't traverse through pieces" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:queen, :white, :a, 1)
        |> Board.put_piece(:pawn, :white, :b, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Qc3")
      end
    end

    test "can capture" do
      match =
        Board.new()
        |> Board.put_piece(:queen, :white, :a, 1)
        |> Board.put_piece(:pawn, :black, :b, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Qxb2")

      piece_at_dest = Board.piece_at(match.board, :b, 2)

      assert piece_at_dest.color == :white
      assert piece_at_dest.type == :queen
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

        match =
          Board.new()
          |> Board.put_piece(:bishop, color, start)
          |> Chexx.play_board(color)
          |> Chexx.move("B#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :bishop
      end
    end

    test "can't traverse through pieces" do
      assert_raise RuntimeError, fn ->
        Board.new()
        |> Board.put_piece(:bishop, :white, :a, 1)
        |> Board.put_piece(:pawn, :white, :b, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Bc3")
      end
    end

    test "can capture" do
      match =
        Board.new()
        |> Board.put_piece(:bishop, :white, :a, 1)
        |> Board.put_piece(:pawn, :black, :b, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Bxb2")

      piece_at_dest = Board.piece_at(match.board, :b, 2)

      assert piece_at_dest.color == :white
      assert piece_at_dest.type == :bishop
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

        match =
          Board.new()
          |> Board.put_piece(:knight, color, start)
          |> Chexx.play_board(color)
          |> Chexx.move("N#{Square.to_algebraic(destination)}")

        piece_at_dest = Board.piece_at(match.board, destination)

        assert piece_at_dest.color == color
        assert piece_at_dest.type == :knight
      end
    end

    test "can traverse through pieces" do
      match =
        Board.new()
        |> Board.put_piece(:knight, :white, :a, 1)
        |> Board.put_piece(:pawn, :white, :a, 2)
        |> Board.put_piece(:pawn, :white, :a, 3)
        |> Board.put_piece(:pawn, :white, :b, 2)
        |> Chexx.play_board(:white)
        |> Chexx.move("Nb3")

      piece_at_dest = Board.piece_at(match.board, :b, 3)

      assert piece_at_dest.color == :white
      assert piece_at_dest.type == :knight
    end

    test "can capture" do
      match =
        Board.new()
        |> Board.put_piece(:knight, :white, :a, 1)
        |> Board.put_piece(:pawn, :black, :b, 3)
        |> Chexx.play_board(:white)
        |> Chexx.move("Nxb3")

      piece_at_dest = Board.piece_at(match.board, :b, 3)

      assert piece_at_dest.color == :white
      assert piece_at_dest.type == :knight
    end
  end

  test "can't put your king into check" do
    assert_raise RuntimeError, fn ->
      Board.new()
      |> Board.put_piece(:king, :white, :a, 1)
      |> Board.put_piece(:rook, :black, :b, 2)
      |> Chexx.play_board(:white)
      |> Chexx.move("Kb1")
    end
  end

  test "black can't move on the first turn of a game" do
    assert_raise RuntimeError, fn ->
      Chexx.start_game()
      |> Chexx.move("c5")
    end
  end

  test "Georg Rotlewi vs Akiba Rubinstein" do
    game =
      Chexx.start_game()
      |> Chexx.moves([
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
      |> Match.resign()

    assert game.status == :black_wins
  end

  test "fool's mate" do
    game =
      Chexx.start_game()
      |> Chexx.moves([
          "f3", "e5",
          "g4", "Qh4#"
      ])

    assert game.status == :black_wins
  end

  test "three-piece mate" do
    game =
      Board.new()
      |> Board.put_piece(:king, :white, :f, 5)
      |> Board.put_piece(:king, :black, :h, 5)
      |> Board.put_piece(:rook, :white, :a, 1)
      |> Chexx.play_board(:white)
      |> Chexx.move("Rh1#")

    assert game.status == :white_wins
  end

  test "Game of the Century" do
    game =
      Chexx.start_game()
      |> Chexx.turns([
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
