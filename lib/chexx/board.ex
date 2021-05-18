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
  alias Chexx.Promotion
  alias Chexx.Color

  import Chexx.Color
  import Chexx.Piece, only: [is_piece: 1]
  import Chexx.Square, only: [is_rank: 1, is_file: 1]

  @type occupied_position() :: %{
    piece: Chexx.Piece.t(),
    square: Chexx.Square.t()
  }

  @type t() :: %__MODULE__{
    occupied_positions: [occupied_position()]
  }

  defstruct [
    occupied_positions: []
  ]

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec put_piece(t(), Chexx.Piece.piece(), Chexx.Color.t(), Chexx.Square.file(), Chexx.Square.rank()) :: t()
  @spec put_piece(t(), Chexx.Piece.piece(), Chexx.Color.t(), Chexx.Square.file_letter(), Chexx.Square.rank()) :: t()
  def put_piece(%__MODULE__{} = board, type, color, file, rank) when is_piece(type) and is_color(color) do
    put_piece(board, type, color, Square.new(file, rank))
  end

  @spec put_piece(t(), Chexx.Piece.piece(), Chexx.Color.t(), Chexx.Square.t()) :: t()
  def put_piece(%__MODULE__{} = board, type, color, %Square{} = square)  when is_piece(type) and is_color(color) do
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

  @spec delete_piece(t(), Chexx.Square.t()) :: t()
  def delete_piece(board, square)

  def delete_piece(%__MODULE__{} = board, nil), do: board

  def delete_piece(%__MODULE__{} = board, %Square{} = square) do
    Map.update!(board, :occupied_positions, fn occupied_positions ->
      Enum.reject(occupied_positions, fn occupied_position ->
        occupied_position.square == square
      end)
    end)
  end

  @spec is_valid_square({Chexx.Square.file(), Chexx.Square.rank()}) :: boolean
  @spec is_valid_square(Chexx.Square.t()) :: boolean

  def is_valid_square({file, rank}) when is_file(file) and is_rank(rank), do: true
  def is_valid_square(%Square{file: file, rank: rank}) when is_file(file) and is_rank(rank), do: true
  def is_valid_square(_), do: false

  @spec piece_at(t(), Chexx.Square.file(), Chexx.Square.rank()) :: Chexx.Piece.t()
  def piece_at(%__MODULE__{} = board, file, row) do
    piece_at(board, Square.new(file, row))
  end

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

  @spec find_pieces(t(), Chexx.Piece.t()) :: [Chexx.Square.t()]
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
      Enum.all?(move.movements, fn movement ->
        case movement do
          %Touch{source: src, piece: expected_piece} ->
            actual_piece = piece_at(board, src)
            expected_piece.color == by and expected_piece == actual_piece
          _ -> true
        end
      end)

    path_clear? =
      Enum.all?(Map.get(move, :traverses, []), fn traversed_square ->
        is_nil(piece_at(board, traversed_square))
      end)

    destination_clear? =
      Enum.all?(move.movements, fn movement ->
          case movement do
            %Touch{destination: dest} ->
              landing_piece = piece_at(board, dest)
              is_nil(landing_piece) or move.captures == dest
            _ -> true
          end
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

    all_touches_present? and path_clear? and capture_valid? and destination_clear?
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

  defp move_piece(%__MODULE__{} = board, %Promotion{} = promotion) do
    piece = piece_at(board, promotion.source)
    promoted_to_piece = promotion.promoted_to

    if is_nil(piece) do
      raise "No piece at #{inspect promotion.source} to promote."
    end

    if promoted_to_piece.color != piece.color do
      raise "Expected a #{promoted_to_piece.color} piece at #{inspect promotion.source}, but it was a #{piece.color} piece."
    end

    board
    |> delete_piece(promotion.source)
    |> put_piece(promoted_to_piece.type, promoted_to_piece.color, promotion.source)
  end

  def to_string(board) do
    for rank <- 8..1, file <- 1..8 do
      Chexx.Board.piece_at(board, file, rank)
    end
    |> Enum.map(fn piece ->
      if is_nil(piece) do
        " "
      else
        Piece.to_unicode(piece)
      end
    end)
    |> Enum.chunk_every(8)
    |> Enum.intersperse("\n")
    |> Enum.join("")
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(board, _opts) do
      Chexx.Board.to_string(board)
    end
  end
end
