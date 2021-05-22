defmodule Chexx.Match do
  alias Chexx.Color
  alias Chexx.Board
  alias Chexx.Piece
  alias Chexx.Ply
  alias Chexx.Promotion

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
    new_match = new(Board.standard())
    case new_match do
      {:ok, match} -> match
      err -> raise "Creating a match from a new board caused an error. This is a bug in Chexx. Error: #{inspect err}"
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
        |> update_status()

      opponent = Color.opponent(game.current_player)

      {:ok, %{game | current_player: opponent}}
    end
  end

  defp update_status(game) do
    status =
      if checkmate?(game, Color.opponent(game.current_player)) do
        case game.current_player do
          :white -> :white_wins
          :black -> :black_wins
        end
      else
        game.status
      end
    %{game | status: status}
  end

  def disambiguate_plies(plies, %__MODULE__{} = game, by, parsed_notation) do
    plies
    |> Enum.filter(&Board.valid_ply?(game.board, by, &1))

    |> Enum.filter(fn possible_ply ->
      match_history_fn = Map.get(possible_ply, :match_history_fn, fn _ -> true end)

      match_history_fn.(game.history)
    end)
    |> Enum.filter(fn ply ->
      opponent = Color.opponent(by)

      expected_check = parsed_notation[:check_status] == :check
      expected_checkmate = parsed_notation[:check_status] == :checkmate

      results_in_check? =
        case Board.move(game.board, ply) do
          {:ok, board} -> king_in_check?(%{game | board: board}, opponent)
          _ -> false
        end

      results_in_checkmate? =
        if results_in_check? do
          case Board.move(game.board, ply) do
            {:ok, board} -> checkmate?(%{game | board: board}, opponent)
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
              touch.promoted_to.type == parsed_notation[:promoted_to]
            _ -> false
          end
        end)
      end
    end)
    |> Enum.reject(fn possible_ply ->
      {:ok, board} = Board.move(game.board, possible_ply)
      king_in_check?(%{game | board: board}, by)
    end)
  end

  defp xor(true, true), do: false
  defp xor(true, false), do: true
  defp xor(false, true), do: true
  defp xor(false, false), do: false

  defp king_in_check?(game, player_in_check) do
    opponent = Color.opponent(player_in_check)
    king = Piece.new(:king, player_in_check)
    king_squares = Board.find_pieces(game.board, king)

    possible_king_captures =
      Enum.flat_map(king_squares, fn king_square ->
        Ply.possible_pawn_sources(opponent, king_square) ++
        Ply.possible_king_sources(opponent, king_square) ++
        Ply.possible_queen_sources(opponent, king_square) ++
        Ply.possible_rook_sources(opponent, king_square) ++
        Ply.possible_bishop_sources(opponent, king_square) ++
        Ply.possible_knight_sources(opponent, king_square)
      end)
      |> Enum.filter(&Board.valid_ply?(game.board, opponent, &1))
      |> Enum.filter(fn possible_ply ->
        match_history_fn = Map.get(possible_ply, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)
      |> Enum.filter(fn possible_ply ->
        is_nil(possible_ply.captured_piece_type) or
         possible_ply.captured_piece_type == :king
      end)

    Enum.count(possible_king_captures) > 0
  end

  defp checkmate?(game, player_checkmated) do
    regular_plies =
      game.board.occupied_positions
      |> Enum.filter(fn occ_pos ->
        occ_pos.piece.color == player_checkmated
      end)
      |> Enum.flat_map(fn %{square: square, piece: piece} ->
        case piece.type do
          :pawn -> Ply.possible_pawn_moves(player_checkmated, square)
          :king -> Ply.possible_king_moves(player_checkmated, square)
          :queen -> Ply.possible_queen_moves(player_checkmated, square)
          :rook -> Ply.possible_rook_moves(player_checkmated, square)
          :bishop -> Ply.possible_bishop_moves(player_checkmated, square)
          :knight -> Ply.possible_knight_moves(player_checkmated, square)
        end
      end)

    all_plies =
      Ply.kingside_castle(player_checkmated) ++
      Ply.queenside_castle(player_checkmated) ++
      regular_plies

    possible_plies =
      all_plies
      |> Enum.filter(&Board.valid_ply?(game.board, player_checkmated, &1))
      |> Enum.filter(fn possible_ply ->
        match_history_fn = Map.get(possible_ply, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)

    all_plies_result_in_check =
      Enum.all?(possible_plies, fn ply ->
        case Board.move(game.board, ply) do
          {:ok, board} -> king_in_check?(%{game | board: board}, player_checkmated)
          _ -> false
        end
      end)

    all_plies_result_in_check
  end
end
