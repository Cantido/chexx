defmodule Chexx.Board do
  @moduledoc """
  A `Board` is a set of `Chexx.Piece`s at certain `Chexx.Square`s.
  Supports adding, removing, and moving pieces.
  Two pieces cannot occupy the same square.
  """

  alias Chexx.Square
  alias Chexx.Piece
  alias Chexx.Move
  alias Chexx.Touch
  alias Chexx.Color

  import Chexx.Color
  import Chexx.Piece, only: [is_piece: 1]
  import Chexx.Square, only: [is_rank: 1, is_file: 1]

  defstruct [
    occupied_positions: []
  ]

  def new do
    %__MODULE__{}
  end

  def put_piece(%__MODULE__{} = board, type, color, file, rank) when is_piece(type) and is_color(color) do
    put_piece(board, type, color, Square.new(file, rank))
  end

  def put_piece(%__MODULE__{} = board, type, color, %Square{} = square) when is_piece(type) and is_color(color) do
    square = Square.new(square)

    if piece = piece_at(board, square) do
      raise "Square #{inspect(square)} square already has piece #{inspect(piece)}."
    end

    if not is_valid_square(square) do
      raise "Square #{inspect(square)} is not a valid place to put a piece"
    end

    occupied_positions = [%{piece: Piece.new(type, color), square: square} | board.occupied_positions]
    %{board | occupied_positions: occupied_positions}
  end

  def delete_piece(%__MODULE__{} = board, nil), do: board

  def delete_piece(%__MODULE__{} = board, %Square{} = square) do
    Map.update!(board, :occupied_positions, fn occupied_positions ->
      Enum.reject(occupied_positions, fn occupied_position ->
        occupied_position.square == square
      end)
    end)
  end

  def is_valid_square({file, rank}) when is_file(file) and is_rank(rank), do: true
  def is_valid_square(%Square{file: file, rank: rank}) when is_file(file) and is_rank(rank), do: true
  def is_valid_square(_), do: false

  def piece_at(_board, nil), do: nil

  def piece_at(%__MODULE__{} = board, %Square{} = square) do
    board.occupied_positions
    |> Enum.find(fn occupied_position ->
      occupied_position.square == square
    end)
    |> case do
      nil -> nil
      occupied_position -> Map.fetch!(occupied_position, :piece)
    end
  end

  def find_pieces(%__MODULE__{} = board, piece) do
    board.occupied_positions
    |> Enum.filter(fn occ_pos ->
      occ_pos.piece == piece
    end)
    |> Enum.map(fn occ_pos ->
      occ_pos.square
    end)
  end

  def valid_move?(%__MODULE__{} = board, by, %Move{} = move) do
    all_touches_present? =
      Enum.all?(move.movements, fn %{source: src, piece: expected_piece} ->
        actual_piece = piece_at(board, src)

        expected_piece.color == by and expected_piece == actual_piece
      end)

    path_clear? =
      Enum.all?(Map.get(move, :traverses, []), fn traversed_square ->
        is_nil(piece_at(board, traversed_square))
      end)

    capture = Map.get(move, :capture, :forbidden)
    captured_square = Map.get(move, :captures)
    captured_piece = piece_at(board, captured_square)

    capture_valid? =
      case capture do
        :required -> not is_nil(captured_piece) and captured_piece.color == Color.opponent(by)
        :allowed -> is_nil(captured_piece) or captured_piece.color == Color.opponent(by)
        _ -> is_nil(captured_piece)
      end

    all_touches_present? and path_clear? and capture_valid?
  end

  def move(%__MODULE__{} = board, %Move{} = move) do
    captured_square = Map.get(move, :captures)

    board = delete_piece(board, captured_square)

    Enum.reduce(move.movements, board, fn touch, board ->
      move_piece(board, touch)
    end)
  end

  defp move_piece(%__MODULE__{} = board, %Touch{} = touch) do
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
