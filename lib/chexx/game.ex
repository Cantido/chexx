defmodule Chexx.Game do
  alias Chexx.Color
  alias Chexx.Board
  alias Chexx.Piece
  alias Chexx.Pieces.King
  alias Chexx.Ply
  alias Chexx.Promotion
  alias Chexx.Touch
  alias Chexx.Games.Standard

  import Chexx.Color

  @derive {Inspect, only: [:status, :current_player]}
  defstruct [
    history: [],
    current_player: :white,
    board: Board.new(),
    status: :in_progress
  ]

  @type parsed_notation() :: map()
  @type ply() :: String.t()
  @type turn() :: String.t()
  @type match_status() :: :in_progress | :white_wins | :black_wins | :draw
  @type t() :: %__MODULE__{
    history: [Chess.Ply.t()],
    current_player: Chexx.Color.t(),
    board: Chexx.Board.t(),
    status: match_status()
  }

  # TODO: don't let a piece move to its own position, i.e. not actually move

  @spec new() :: t()
  def new do
    new_match = new(Standard.new_board())
    case new_match do
      {:ok, match} -> match
    end
  end

  @spec new(Chexx.Board.t()) :: {:ok, t()} | {:error, any()}
  def new(%Board{} = board) do
    # TODO: Validate that the board is a valid game, ex. both sides have pieces
    {:ok, %__MODULE__{board: board}}
  end

  @spec new(Chexx.Board.t(), Chexx.Color.t()) :: {:ok, t()} | {:error, any()}
  def new(%Board{} = board, color) when is_color(color) do
    # TODO: Validate that the board is a valid game, ex. both sides have pieces
    {:ok, %__MODULE__{board: board, current_player: color}}
  end

  @spec put_ply(t(), Chexx.Ply.t()) :: t()
  defp put_ply(game, ply) do
    %{game | history: [ply | game.history]}
  end

  @spec resign(t()) :: {:ok, t()} | {:error, any()}
  def resign(game) do
    status =
      case game.current_player do
        :white -> :black_wins
        :black -> :white_wins
      end

    {:ok, %{game | status: status}}
  end

  @spec move(t(), Chexx.Ply.t()) :: {:ok, t()} | {:error, any()}
  def move(%__MODULE__{} = game, %Ply{} = ply) do
    with {:ok, board} <- Board.move(game.board, ply) do
      game =
        %{game | board: board}
        |> put_ply(ply)

      opponent = Color.opponent(game.current_player)

      game = update_status(%{game | current_player: opponent})

      {:ok, game}
    end
  end

  defp update_status(game) do
    legal_plies = legal_plies(game)
    check? = check?(game)

    checkmate? = check? and Enum.empty?(legal_plies)
    stalemate? = (not check?) and Enum.empty?(legal_plies)

    status =
      cond do
        checkmate? ->
          case game.current_player do
            :white -> :black_wins
            :black -> :white_wins
          end
        stalemate? ->
          :draw
        true ->
          game.status
      end
    %{game | status: status}
  end

  def disambiguate_plies(plies, %__MODULE__{} = game, parsed_notation) do
    plies
    |> Enum.filter(&valid_ply?(game.board, &1))

    |> Enum.filter(fn possible_ply ->
      match_history_fn = Map.get(possible_ply, :match_history_fn, fn _ -> true end)

      match_history_fn.(game.history)
    end)
    |> Enum.filter(fn ply ->
      opponent = Color.opponent(ply.player)

      expected_check = parsed_notation[:check_status] == :check
      expected_checkmate = parsed_notation[:check_status] == :checkmate

      results_in_check? =
        case Board.move(game.board, ply) do
          {:ok, board} -> check?(%{game | board: board, current_player: opponent})
          _ -> false
        end

      results_in_checkmate? =
        if results_in_check? do
          case Board.move(game.board, ply) do
            {:ok, board} -> checkmate?(%{game | board: board, current_player: opponent})
            _ -> false
          end
        else
          false
        end

      valid_check_notation = not xor(expected_check, results_in_check?)
      valid_checkmate_notation = not xor(expected_checkmate, results_in_checkmate?)

      if results_in_checkmate? do
        valid_checkmate_notation
      else
        valid_check_notation
      end
    end)
    |> Enum.filter(fn possible_ply ->
      if not is_nil(parsed_notation[:source_file]) do
        if parsed_notation.move_type == :regular do
          [touch] = possible_ply.touches
          parsed_notation.source_file == touch.source.file
        else
          true
        end
      else
        true
      end
    end)
    |> Enum.filter(fn possible_ply ->
      if is_nil(parsed_notation[:promoted_to]) do
        not Ply.any_promotions?(possible_ply)
      else
        Enum.any?(possible_ply.touches, fn touch ->
          case touch do
            %Promotion{} ->
              Piece.type(touch.promoted_to) == parsed_notation[:promoted_to]
            _ -> false
          end
        end)
      end
    end)
    |> Enum.reject(fn possible_ply ->
      {:ok, board} = Board.move(game.board, possible_ply)
      check?(%{game | board: board, current_player: possible_ply.player})
    end)
  end

  defp xor(true, true), do: false
  defp xor(true, false), do: true
  defp xor(false, true), do: true
  defp xor(false, false), do: false

  defp check?(game) do
    player_in_check = game.current_player
    opponent = Color.opponent(player_in_check)
    king = %King{color: player_in_check}
    king_squares = Board.find_pieces(game.board, king)

    possible_king_captures =
      game.board.occupied_positions
      |> Enum.filter(fn %{piece: piece} ->
        piece.color == opponent
      end)
      |> Enum.map(& &1.piece)
      |> Enum.uniq()
      |> combinations(king_squares)
      |> Enum.flat_map(fn {piece, king_square} ->
        Piece.moves_to(piece, king_square)
      end)
      |> Enum.filter(&legal_ply?(game, &1))
      |> Enum.filter(&match_history_allows?(game, &1))
      |> Enum.filter(fn possible_ply ->
        is_nil(possible_ply.captured_piece_type) or
         possible_ply.captured_piece_type == :king
      end)

    Enum.count(possible_king_captures) > 0
  end

  defp combinations(enum1, enum2) do
    Enum.flat_map(enum1, fn elem1 ->
      Enum.map(enum2, &{elem1, &1})
    end)
  end

  def checkmate?(game) do
    check?(game) and Enum.empty?(legal_plies(game))
  end

  def stalemate?(game) do
    (not check?(game)) and Enum.empty?(legal_plies(game))
  end

  defp legal_plies(game) do
    player = game.current_player
    all_plies =
      game.board.occupied_positions
      |> Enum.filter(fn occ_pos ->
        occ_pos.piece.color == player
      end)
      |> Enum.flat_map(fn %{square: square, piece: piece} ->
        Piece.moves_from(piece, square)
      end)

    Enum.filter(all_plies, &legal_ply?(game, &1))
  end

  defp match_history_allows?(game, ply) do
    match_history_fn = Map.get(ply, :match_history_fn, fn _ -> true end)
    match_history_fn.(game.history)
  end

  def legal_ply?(game, ply) do
    valid_on_board? = valid_ply?(game.board, ply)

    match_history_allows? = match_history_allows?(game, ply)

    ply_puts_player_in_check? =
      case Board.move(game.board, ply) do
        {:ok, board} -> check?(%{game | board: board})
        _ -> false
      end

    valid_on_board? and match_history_allows? and not ply_puts_player_in_check?
  end

  def valid_ply?(%Board{} = board, %Ply{} = ply) do
    player_making_move = ply.player

    all_touches_present? =
      Enum.all?(ply.touches, fn touch ->
        case touch do
          %Touch{source: src, piece: expected_piece} ->
            actual_piece = Board.piece_at(board, src)
            expected_piece.color == player_making_move and expected_piece == actual_piece
          _ -> true
        end
      end)

    path_clear? =
      Enum.all?(Map.get(ply, :traverses, []), fn traversed_square ->
        is_nil(Board.piece_at(board, traversed_square))
      end)

    destination_clear? =
      Enum.all?(ply.touches, fn touch ->
          case touch do
            %Touch{destination: dest} ->
              landing_piece = Board.piece_at(board, dest)
              is_nil(landing_piece) or ply.captures == dest
            _ -> true
          end
      end)

    capture = Map.get(ply, :capture, :forbidden)
    captured_square = Map.get(ply, :captures)
    captured_piece = Board.piece_at(board, captured_square)

    capturing_correct_piece? =
      is_nil(captured_piece) or is_nil(ply.captured_piece_type) or (ply.captured_piece_type == Piece.type(captured_piece))

    capture_valid? =
      case capture do
        :required -> not is_nil(captured_piece) and captured_piece.color == Color.opponent(player_making_move) and capturing_correct_piece?
        :allowed -> is_nil(captured_piece) or captured_piece.color == Color.opponent(player_making_move) and capturing_correct_piece?
        _ -> is_nil(captured_piece)
      end

    all_touches_present? and path_clear? and capture_valid? and destination_clear?
  end
end
