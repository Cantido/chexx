defmodule Chexx.Game do
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
              touch.promoted_to.type == parsed_notation[:promoted_to]
            _ -> false
          end
        end)
      end
    end)
    |> Enum.reject(fn possible_ply ->
      {:ok, board} = Board.move(game.board, possible_ply)
      check?(%{game | board: board, current_player: by})
    end)
  end

  defp xor(true, true), do: false
  defp xor(true, false), do: true
  defp xor(false, true), do: true
  defp xor(false, false), do: false

  defp check?(game) do
    player_in_check = game.current_player
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

  def checkmate?(game) do
    check?(game) and Enum.empty?(legal_plies(game))
  end

  def stalemate?(game) do
    (not check?(game)) and Enum.empty?(legal_plies(game))
  end

  defp legal_plies(game) do
    player = game.current_player
    regular_plies =
      game.board.occupied_positions
      |> Enum.filter(fn occ_pos ->
        occ_pos.piece.color == player
      end)
      |> Enum.flat_map(fn %{square: square, piece: piece} ->
        Piece.moves_from(piece, square)
      end)

    all_plies =
      Ply.kingside_castle(player) ++
      Ply.queenside_castle(player) ++
      regular_plies


    Enum.filter(all_plies, &legal_ply?(game, &1))
  end

  def legal_ply?(game, ply) do
    valid_on_board? = Board.valid_ply?(game.board, game.current_player, ply)

    match_history_fn = Map.get(ply, :match_history_fn, fn _ -> true end)
    match_history_allows? = match_history_fn.(game.history)

    ply_puts_player_in_check? =
      case Board.move(game.board, ply) do
        {:ok, board} -> check?(%{game | board: board})
        _ -> false
      end

    valid_on_board? and match_history_allows? and not ply_puts_player_in_check?
  end
end
