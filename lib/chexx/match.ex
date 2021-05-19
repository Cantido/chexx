defmodule Chexx.Match do
  alias Chexx.Color
  alias Chexx.Square
  alias Chexx.Board
  alias Chexx.Piece
  alias Chexx.Move
  alias Chexx.Promotion

  import Chexx.Color

  defstruct [
    history: [],
    current_player: :white,
    board: Board.new(),
    status: :in_progress
  ]

  @type parsed_notation() :: map()
  @type move() :: String.t()
  @type turn() :: String.t()
  @type match_status() :: :in_progress | :white_wins | :black_wins | :draw
  @type t() :: %__MODULE__{
    history: [String.t()],
    current_player: Chexx.Color.t(),
    board: Chexx.Board.t(),
    status: match_status()
  }

  # TODO: don't let a piece move to its own position, i.e. not actually move

  @spec new() :: t()
  def new do
    Board.new()
    |> Board.put_piece(:pawn, :white, :a, 2)
    |> Board.put_piece(:pawn, :white, :b, 2)
    |> Board.put_piece(:pawn, :white, :c, 2)
    |> Board.put_piece(:pawn, :white, :d, 2)
    |> Board.put_piece(:pawn, :white, :e, 2)
    |> Board.put_piece(:pawn, :white, :f, 2)
    |> Board.put_piece(:pawn, :white, :g, 2)
    |> Board.put_piece(:pawn, :white, :h, 2)

    |> Board.put_piece(:rook, :white, :a, 1)
    |> Board.put_piece(:knight, :white, :b, 1)
    |> Board.put_piece(:bishop, :white, :c, 1)
    |> Board.put_piece(:queen, :white, :d, 1)
    |> Board.put_piece(:king, :white, :e, 1)
    |> Board.put_piece(:bishop, :white, :f, 1)
    |> Board.put_piece(:knight, :white, :g, 1)
    |> Board.put_piece(:rook, :white, :h, 1)

    |> Board.put_piece(:pawn, :black, :a, 7)
    |> Board.put_piece(:pawn, :black, :b, 7)
    |> Board.put_piece(:pawn, :black, :c, 7)
    |> Board.put_piece(:pawn, :black, :d, 7)
    |> Board.put_piece(:pawn, :black, :e, 7)
    |> Board.put_piece(:pawn, :black, :f, 7)
    |> Board.put_piece(:pawn, :black, :g, 7)
    |> Board.put_piece(:pawn, :black, :h, 7)

    |> Board.put_piece(:rook, :black, :a, 8)
    |> Board.put_piece(:knight, :black, :b, 8)
    |> Board.put_piece(:bishop, :black, :c, 8)
    |> Board.put_piece(:queen, :black, :d, 8)
    |> Board.put_piece(:king, :black, :e, 8)
    |> Board.put_piece(:bishop, :black, :f, 8)
    |> Board.put_piece(:knight, :black, :g, 8)
    |> Board.put_piece(:rook, :black, :h, 8)
    |> new()
  end

  @spec new(Chexx.Board.t()) :: t()
  def new(%Board{} = board) do
    %__MODULE__{board: board}
  end

  @spec new(Chexx.Board.t(), Chexx.Color.t()) :: t()
  def new(%Board{} = board, color) when is_color(color) do
    %__MODULE__{board: board, current_player: color}
  end

  @spec piece_at(t(), Chexx.Square.t() | {Chexx.Square.file(), Chexx.Square.rank()} | {Chexx.Square.file_letter(), Chexx.Square.rank()}) :: Chexx.Piece.t()
  def piece_at(game, square) do
    Board.piece_at(game.board, Square.new(square))
  end

  @spec piece_at(t(), Chexx.Square.file() | Chexx.Square.file_letter(), Chexx.Square.rank()) :: Chexx.Piece.t()
  def piece_at(game, file, rank) do
    Board.piece_at(game.board, Square.new(file, rank))
  end

  @spec put_move(t(), String.t()) :: t()
  defp put_move(game, move) do
    Map.update!(game, :history, fn history ->
      [move | history]
    end)
  end

  @spec resign(t()) :: t()
  def resign(game) do
    status =
      case game.current_player do
        :white -> :black_wins
        :black -> :white_wins
      end

    %{game | status: status}
  end

  @spec move(t(), Chexx.Move.t()) :: t()
  def move(%__MODULE__{} = game, %Move{} = move) do
    game =
      game
      |> Map.update!(:board, &Board.move(&1, move))
      |> put_move(move)
      |> update_status()

    opponent = Color.opponent(game.current_player)

    %{game | current_player: opponent}
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

  def disambiguate_moves(moves, game, by, parsed_notation) do
    moves
    |> Enum.filter(&Board.valid_move?(game.board, by, &1))

    |> Enum.filter(fn possible_move ->
      match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

      match_history_fn.(game.history)
    end)
    |> Enum.filter(fn move ->
      opponent = Color.opponent(by)

      expected_check = parsed_notation[:check_status] == :check
      expected_checkmate = parsed_notation[:check_status] == :checkmate

      board = Board.move(game.board, move)
      results_in_check? = king_in_check?(%{game | board: board}, opponent)

      results_in_checkmate? =
        if results_in_check? do
          checkmate?(%{game | board: board}, opponent)
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
    |> Enum.filter(fn possible_move ->
      if not is_nil(parsed_notation[:source_file]) do
        if parsed_notation.move_type == :regular do
          [touch] = possible_move.movements
          parsed_notation.source_file == Square.file(touch.source)
        else
          true
        end
      else
        true
      end
    end)
    |> Enum.filter(fn possible_move ->
      if is_nil(parsed_notation[:promoted_to]) do
        not Move.any_promotions?(possible_move)
      else
        Enum.any?(possible_move.movements, fn movement ->
          case movement do
            %Promotion{} ->
              movement.promoted_to.type == parsed_notation[:promoted_to]
            _ -> false
          end
        end)
      end
    end)
    |> Enum.reject(fn possible_move ->
      board = Board.move(game.board, possible_move)
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
        Move.possible_pawn_sources(opponent, king_square) ++
        Move.possible_king_sources(opponent, king_square) ++
        Move.possible_queen_sources(opponent, king_square) ++
        Move.possible_rook_sources(opponent, king_square) ++
        Move.possible_bishop_sources(opponent, king_square) ++
        Move.possible_knight_sources(opponent, king_square)
      end)
      |> Enum.filter(&Board.valid_move?(game.board, opponent, &1))
      |> Enum.filter(fn possible_move ->
        match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)
      |> Enum.filter(fn possible_move ->
        is_nil(possible_move.captured_piece_type) or
         possible_move.captured_piece_type == :king
      end)

    Enum.count(possible_king_captures) > 0
  end

  defp checkmate?(game, player_checkmated) do
    regular_moves =
      game.board.occupied_positions
      |> Enum.filter(fn occ_pos ->
        occ_pos.piece.color == player_checkmated
      end)
      |> Enum.flat_map(fn %{square: square, piece: piece} ->
        case piece.type do
          :pawn -> Move.possible_pawn_moves(player_checkmated, square)
          :king -> Move.possible_king_moves(player_checkmated, square)
          :queen -> Move.possible_queen_moves(player_checkmated, square)
          :rook -> Move.possible_rook_moves(player_checkmated, square)
          :bishop -> Move.possible_bishop_moves(player_checkmated, square)
          :knight -> Move.possible_knight_moves(player_checkmated, square)
        end
      end)

    all_moves =
      Move.kingside_castle(player_checkmated) ++
      Move.queenside_castle(player_checkmated) ++
      regular_moves

    possible_moves =
      all_moves
      |> Enum.filter(&Board.valid_move?(game.board, player_checkmated, &1))
      |> Enum.filter(fn possible_move ->
        match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)

    all_moves_result_in_check =
      Enum.all?(possible_moves, fn move ->
        board = Board.move(game.board, move)
        king_in_check?(%{game | board: board}, player_checkmated)
      end)

    all_moves_result_in_check
  end
end
