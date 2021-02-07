defmodule Chexx.Board do
  @moduledoc """
  A `Board` is a set of `Chexx.Piece`s at certain `Chexx.Square`s.
  Supports adding, removing, and moving pieces.
  Two pieces cannot occupy the same square.
  """

  alias Chexx.Square
  alias Chexx.Piece

  import Chexx, only: [
    is_color: 1,
    is_piece: 1,
    is_valid_square: 1
  ]

  defstruct [
    occupied_positions: []
  ]

  def new do
    %__MODULE__{}
  end

  def put_piece(board, type, color, square) when is_piece(type) and is_color(color) do
    square = Square.new(square)

    if piece = piece_at(board, square) do
      raise "Square #{inspect(square)} square already has piece #{inspect(piece)}."
    end

    if not is_valid_square(square) do
      raise "Square #{inspect(square)}is not a valid place to put a piece"
    end

    occupied_positions = [%{piece: Piece.new(type, color), square: square} | board.occupied_positions]
    %{board | occupied_positions: occupied_positions}
  end

  def delete_piece(board, square) when is_nil(square), do: board

  def delete_piece(board, square) do
    Map.update!(board, :occupied_positions, fn occupied_positions ->
      Enum.reject(occupied_positions, fn occupied_position ->
        occupied_position.square == square
      end)
    end)
  end

  def piece_at(_board, nil), do: nil

  def piece_at(board, square) do
    board.occupied_positions
    |> Enum.find(fn occupied_position ->
      occupied_position.square == Square.new(square)
    end)
    |> case do
      nil -> nil
      occupied_position -> Map.fetch!(occupied_position, :piece)
    end
  end

  def move(board, _by, move) do
    captured_square = Map.get(move, :captures)

    board = delete_piece(board, captured_square)

    Enum.reduce(move.movements, board, fn touch, board ->
      move_piece(board, touch)
    end)
  end

  defp move_piece(board, touch) do
    piece = piece_at(board, touch.source)

    if is_nil(piece) do
      raise "No piece at #{inspect touch.source} to move."
    end

    if touch.piece.type != piece.type do
      raise "Expected a #{touch.piece.type} to be at #{inspect touch.source}, but it was a #{piece.type} instead."
    end

    if touch.piece.color != piece.color do
      raise "Expected a #{touch.piece.color} piece at #{inspect touch.source}, but it was a #{piece.color} piece."
    end

    board
    |> delete_piece(touch.source)
    |> put_piece(piece.type, piece.color, touch.destination)
  end
end
