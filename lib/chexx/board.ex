defmodule Chexx.Board do
  @moduledoc """
  A `Board` is a set of `Chexx.Piece`s at certain `Chexx.Square`s.
  Supports adding, removing, and moving pieces.
  Two pieces cannot occupy the same square.
  """

  alias Chexx.Square

  import Chexx, only: [
    is_color: 1,
    is_piece: 1,
    is_valid_square: 1
  ]

  def new do
    %{pieces: []}
  end

  def put_piece(board, type, color, square) when is_piece(type) and is_color(color) do
    square = Square.new(square)

    if piece = piece_at(board, square) do
      raise "Square #{inspect(square)} square already has piece #{inspect(piece)}."
    end

    if not is_valid_square(square) do
      raise "Square #{inspect(square)}is not a valid place to put a piece"
    end

    pieces = [%{type: type, color: color, square: square} | board.pieces]
    %{board | pieces: pieces}
  end

  def delete_piece(board, square) when is_nil(square), do: board

  def delete_piece(board, square) do
    Map.update!(board, :pieces, fn pieces ->
      Enum.reject(pieces, fn piece ->
        piece.square == square
      end)
    end)
  end

  def piece_at(_board, nil), do: nil

  def piece_at(board, square) do
    board.pieces
    |> Enum.find(fn piece ->
      piece.square == Square.new(square)
    end)
    |> case do
      nil -> nil
      piece ->
        Map.take(piece, [
          :type,
          :color
        ])
    end
  end

  def move(board, by, move) do
    Enum.reduce(move.movements, board, fn %{source: src, destination: dest, piece_type: piece_type}, board ->
      move_piece(board, src, dest, captures: Map.get(move, :captures), expect_type: piece_type, expect_color: by)
    end)
  end

  defp move_piece(board, source, dest, opts) do
    piece = piece_at(board, source)

    if is_nil(piece) do
      raise "No piece at #{inspect source} to move."
    end

    if type = Keyword.get(opts, :expect_type) do
      if type != piece.type do
        raise "Expected a #{type} to be at #{inspect source}, but it was a #{piece.type} instead."
      end
    end

    if color = Keyword.get(opts, :expect_color) do
      if color != piece.color do
        raise "Expected a #{color} piece at #{inspect source}, but it was a #{piece.color} piece."
      end
    end

    captured_square = Keyword.get(opts, :captures)

    board
    |> delete_piece(captured_square)
    |> delete_piece(source)
    |> put_piece(piece.type, piece.color, dest)
  end
end
