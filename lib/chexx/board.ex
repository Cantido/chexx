defmodule Chexx.Board do
  @moduledoc """
  A `Board` is a set of `Chexx.Piece`s at certain `Chexx.Square`s.
  Supports adding, removing, and moving pieces.
  Two pieces cannot occupy the same square.
  """

  alias Chexx.Square
  alias Chexx.Piece
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }
  alias Chexx.Ply
  alias Chexx.Touch
  alias Chexx.Promotion
  alias Chexx.Color

  import Chexx.Square, only: [is_rank: 1, is_file: 1]
  import OK, only: [~>>: 2]

  @type occupied_position() :: %{
    piece: Chexx.Piece.t(),
    square: Chexx.Square.t()
  }

  @type t() :: %__MODULE__{
    occupied_positions: [occupied_position()]
  }

  @type move_error() :: :invalid_destination | :square_occupied

  defstruct [
    occupied_positions: []
  ]

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec standard() :: t()
  def standard do
    white_pawn = %Pawn{color: :white}
    black_pawn = %Pawn{color: :black}
    completed_board =
      {:ok, new()}
      ~>> put_piece(white_pawn, :a, 2)
      ~>> put_piece(white_pawn, :b, 2)
      ~>> put_piece(white_pawn, :c, 2)
      ~>> put_piece(white_pawn, :d, 2)
      ~>> put_piece(white_pawn, :e, 2)
      ~>> put_piece(white_pawn, :f, 2)
      ~>> put_piece(white_pawn, :g, 2)
      ~>> put_piece(white_pawn, :h, 2)

      ~>> put_piece(%Rook{color: :white}, :a, 1)
      ~>> put_piece(%Knight{color: :white}, :b, 1)
      ~>> put_piece(%Bishop{color: :white}, :c, 1)
      ~>> put_piece(%Queen{color: :white}, :d, 1)
      ~>> put_piece(%King{color: :white}, :e, 1)
      ~>> put_piece(%Bishop{color: :white}, :f, 1)
      ~>> put_piece(%Knight{color: :white}, :g, 1)
      ~>> put_piece(%Rook{color: :white}, :h, 1)

      ~>> put_piece(black_pawn, :a, 7)
      ~>> put_piece(black_pawn, :b, 7)
      ~>> put_piece(black_pawn, :c, 7)
      ~>> put_piece(black_pawn, :d, 7)
      ~>> put_piece(black_pawn, :e, 7)
      ~>> put_piece(black_pawn, :f, 7)
      ~>> put_piece(black_pawn, :g, 7)
      ~>> put_piece(black_pawn, :h, 7)

      ~>> put_piece(%Rook{color: :black}, :a, 8)
      ~>> put_piece(%Knight{color: :black}, :b, 8)
      ~>> put_piece(%Bishop{color: :black}, :c, 8)
      ~>> put_piece(%Queen{color: :black}, :d, 8)
      ~>> put_piece(%King{color: :black}, :e, 8)
      ~>> put_piece(%Bishop{color: :black}, :f, 8)
      ~>> put_piece(%Knight{color: :black}, :g, 8)
      ~>> put_piece(%Rook{color: :black}, :h, 8)

    case completed_board do
      {:ok, board} -> board
      err -> raise "Setting up a board resulted in an error. This is a bug in Chexx. Error: #{inspect err}"
    end
  end

  @spec put_piece(t(), Chexx.Piece.t(), Chexx.Square.file(), Chexx.Square.rank()) :: {:ok, t()} | {:error, any()}
  @spec put_piece(t(), Chexx.Piece.t(), Chexx.Square.file_letter(), Chexx.Square.rank()) :: {:ok, t()} | {:error, any()}
  def put_piece(%__MODULE__{} = board, piece, file, rank) do
    put_piece(board, piece, Square.new(file, rank))
  end

  @spec put_piece(t(), Chexx.Piece.t(), Chexx.Square.t()) :: {:ok, t()} | {:error, move_error()}
  def put_piece(%__MODULE__{} = board, piece, %Square{} = square) do
    square = Square.new(square)
    piece_at_square = piece_at(board, square)

    cond do
      not is_valid_square(square) -> {:error, :invalid_destination}
      not is_nil(piece_at_square) -> {:error, :square_occupied}
      true ->
        occupied_positions = [%{piece: piece, square: square} | board.occupied_positions]
        {:ok, %{board | occupied_positions: occupied_positions}}
    end
  end

  @spec delete_piece(t(), Chexx.Square.file(), Chexx.Square.rank()) :: t()
  def delete_piece(board, file, rank), do: delete_piece(board, Square.new(file, rank))

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

  def valid_ply?(%__MODULE__{} = board, by, %Ply{} = ply) do
    all_touches_present? =
      Enum.all?(ply.touches, fn touch ->
        case touch do
          %Touch{source: src, piece: expected_piece} ->
            actual_piece = piece_at(board, src)
            expected_piece.color == by and expected_piece == actual_piece
          _ -> true
        end
      end)

    path_clear? =
      Enum.all?(Map.get(ply, :traverses, []), fn traversed_square ->
        is_nil(piece_at(board, traversed_square))
      end)

    destination_clear? =
      Enum.all?(ply.touches, fn touch ->
          case touch do
            %Touch{destination: dest} ->
              landing_piece = piece_at(board, dest)
              is_nil(landing_piece) or ply.captures == dest
            _ -> true
          end
      end)

    capture = Map.get(ply, :capture, :forbidden)
    captured_square = Map.get(ply, :captures)
    captured_piece = piece_at(board, captured_square)

    capturing_correct_piece? =
      is_nil(captured_piece) or is_nil(ply.captured_piece_type) or (ply.captured_piece_type == Piece.type(captured_piece))

    capture_valid? =
      case capture do
        :required -> not is_nil(captured_piece) and captured_piece.color == Color.opponent(by) and capturing_correct_piece?
        :allowed -> is_nil(captured_piece) or captured_piece.color == Color.opponent(by) and capturing_correct_piece?
        _ -> is_nil(captured_piece)
      end

    all_touches_present? and path_clear? and capture_valid? and destination_clear?
  end

  @spec move(t(), Chexx.Ply.t()) :: {:ok, t()} | {:error, any()}
  def move(%__MODULE__{} = board, %Ply{} = ply) do
    captured_square = Map.get(ply, :captures)

    board = delete_piece(board, captured_square)

    Enum.reduce_while(ply.touches, {:ok, board}, fn touch, {:ok, board} ->
      case move_piece(board, touch) do
        {:ok, board} -> {:cont, {:ok, board}}
        err -> {:halt, err}
      end
    end)
  end

  @spec move_piece(t(), Chexx.Touch.t()) :: {:ok, t()} | {:error, any()}
  defp move_piece(%__MODULE__{} = board, %Touch{} = touch) do
    piece = piece_at(board, touch.source)

    cond do
      is_nil(piece) -> {:error, {:invalid_ply, "No piece at #{inspect touch.source} to move."}}
      Piece.type(touch.piece) != Piece.type(piece) -> {:error, {:invalid_ply, "Expected a #{Piece.type(touch.piece)} to be at #{inspect touch.source}, but it was a #{Piece.type(piece)} instead."}}
      Piece.color(touch.piece) != Piece.color(piece) -> {:error, {:invalid_ply, "Expected a #{Piece.color(touch.piece)} piece at #{inspect touch.source}, but it was a #{Piece.color(piece)} piece."}}
      true ->
        board
        |> delete_piece(touch.source)
        |> put_piece(piece, touch.destination)
    end
  end

  @spec move_piece(t(), Chexx.Promotion.t()) :: {:ok, t()} | {:error, any()}
  defp move_piece(%__MODULE__{} = board, %Promotion{} = promotion) do
    piece = piece_at(board, promotion.source)
    promoted_to_piece = promotion.promoted_to

    cond do
      is_nil(piece) -> {:error, {:invalid_ply, "No piece at #{inspect promotion.source} to promote."}}
      Piece.color(promoted_to_piece) != Piece.color(piece) -> {:error, {:invalid_ply, "Expected a #{Piece.color(promoted_to_piece)} piece at #{inspect promotion.source}, but it was a #{Piece.color(piece)} piece."}}
      true ->
        moved_board =
          board
          |> delete_piece(promotion.source)
          |> put_piece(promoted_to_piece, promotion.source)
        moved_board
    end
  end

  def to_string(board) do
    for rank <- 8..1, file <- 1..8 do
      Chexx.Board.piece_at(board, file, rank)
    end
    |> Enum.map(fn piece ->
      if is_nil(piece) do
        " "
      else
        Piece.to_string(piece)
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
