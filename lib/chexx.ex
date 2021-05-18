defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  alias Chexx.AlgebraicNotation
  alias Chexx.Color
  alias Chexx.Square
  alias Chexx.Board
  alias Chexx.Piece
  alias Chexx.Move
  alias Chexx.Touch
  alias Chexx.Promotion

  import Chexx.Color

  defstruct [
    history: [],
    current_player: :white,
    board: Board.new(),
    status: :in_progress
  ]

  # TODO: don't let a piece move to its own position, i.e. not actually move

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

  def new(%Board{} = board) do
    %__MODULE__{board: board}
  end

  def new(%Board{} = board, color) when is_color(color) do
    %__MODULE__{board: board, current_player: color}
  end

  def piece_at(game, square) do
    Board.piece_at(game.board, Square.new(square))
  end

  def piece_at(game, file, rank) do
    Board.piece_at(game.board, Square.new(file, rank))
  end

  defp put_move(game, move) do
    Map.update!(game, :history, fn history ->
      [move | history]
    end)
  end

  def turn(game, move1, move2) do
    game
    |> move(move1)
    |> move(move2)
  end

  def moves(game, moves) when is_list(moves) do
    Enum.reduce(moves, game, fn move, game ->
      move(game, move)
    end)
  end

  def turns(game, turns) when is_list(turns) do
    Enum.reduce(turns, game, fn turn, game ->
      moves(game, String.split(turn))
    end)
  end

  def resign(game) do
    status =
      case game.current_player do
        :white -> :black_wins
        :black -> :white_wins
      end

    %{game | status: status}
  end

  def move(game, notation) do
    unless game.status == :in_progress do
      raise "Game ended, status: #{game.status}"
    end

    parsed_notation =  AlgebraicNotation.parse(notation)
    moves =
      possible_moves(parsed_notation, game.current_player)
      |> disambiguate_moves(game, game.current_player, parsed_notation)


    if Enum.empty?(moves) do
      raise "No valid moves found for #{game.current_player} matching #{inspect notation}. on this board: \n#{inspect(game.board)}\n"
    end

    possible_moves_count = Enum.count(moves)
    if possible_moves_count > 1 do
      raise "Ambiguous move: notation #{notation} can mean #{possible_moves_count} possible moves: #{inspect moves}"
    end

    move = Enum.at(moves, 0)

    board = Board.move(game.board, move)
    opponent = Color.opponent(game.current_player)

    game = put_move(game, notation)

    game_status =
      if parsed_notation[:check_status] == :checkmate do
        case game.current_player do
          :white -> :white_wins
          :black -> :black_wins
        end
      else
        game.status
      end

    %{game | board: board, current_player: opponent, status: game_status}
  end

  defp possible_moves(notation, player) do
    case notation.move_type do
      :kingside_castle -> kingside_castle(player)
      :queenside_castle -> queenside_castle(player)
      :regular ->
        case notation.piece_type do
          :pawn -> possible_pawn_sources(player, notation.destination)
          :king -> possible_king_sources(player, notation.destination)
          :queen -> possible_queen_sources(player, notation.destination)
          :rook -> possible_rook_sources(player, notation.destination)
          :bishop -> possible_bishop_sources(player, notation.destination)
          :knight -> possible_knight_sources(player, notation.destination)
        end
    end
  end

  defp disambiguate_moves(moves, game, by, parsed_notation) do
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
        possible_pawn_sources(opponent, king_square) ++
        possible_king_sources(opponent, king_square) ++
        possible_queen_sources(opponent, king_square) ++
        possible_rook_sources(opponent, king_square) ++
        possible_bishop_sources(opponent, king_square) ++
        possible_knight_sources(opponent, king_square)
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
          :pawn -> possible_pawn_moves(player_checkmated, square)
          :king -> possible_king_moves(player_checkmated, square)
          :queen -> possible_queen_moves(player_checkmated, square)
          :rook -> possible_rook_moves(player_checkmated, square)
          :bishop -> possible_bishop_moves(player_checkmated, square)
          :knight -> possible_knight_moves(player_checkmated, square)
        end
      end)

    all_moves =
      kingside_castle(player_checkmated) ++
      queenside_castle(player_checkmated) ++
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

  defp kingside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          forbidden_string =
            case by do
              :white -> "Ke1"
              :black -> "Ke8"
            end

          String.starts_with?(move, forbidden_string)
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          forbidden_string =
            case by do
              :white -> "Rh1"
              :black -> "Rh8"
            end

          String.starts_with?(move, forbidden_string)
        end)

      not king_moved_before? and not rook_moved_before?
    end


    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:g, 1)
        :black -> Square.new(:g, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:h, 1)
        :black -> Square.new(:h, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:f, 1)
        :black -> Square.new(:f, 8)
      end

    [Move.new(%{
      movements: [
        Touch.new(king_start_pos, king_dest_pos, Piece.new(:king, by)),
        Touch.new(rook_start_pos, rook_dest_pos, Piece.new(:rook, by)),
      ],
      match_history_fn: match_history_fn
    })]
  end

  defp queenside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          forbidden_string =
            case by do
              :white -> "Ke1"
              :black -> "Ke8"
            end

          String.starts_with?(move, forbidden_string)
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          forbidden_string =
            case by do
              :white -> "Ra1"
              :black -> "Ra8"
            end

          String.starts_with?(move, forbidden_string)
        end)

      not king_moved_before? and not rook_moved_before?
    end

    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:c, 1)
        :black -> Square.new(:c, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:a, 1)
        :black -> Square.new(:a, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:d, 1)
        :black -> Square.new(:d, 8)
      end

    traversed_square =
      case by do
        :white -> Square.new(:b, 1)
        :black -> Square.new(:b, 8)
      end

    [Move.new(%{
      movements: [
        Touch.new(king_start_pos, king_dest_pos, Piece.new(:king, by)),
        Touch.new(rook_start_pos, rook_dest_pos, Piece.new(:rook, by)),
      ],
      traverses: [traversed_square],
      match_history_fn: match_history_fn
    })]
  end

  def piece_equals?(piece, color, type) do
    not is_nil(piece) and piece.color == color and piece.type == type
  end

  defp possible_pawn_moves(player, source) do
    piece = Piece.new(:pawn, player)
    advance_direction =
      case player do
        :white -> :up
        :black -> :down
      end
    start_rank =
      case player do
        :white -> 2
        :black -> 7
      end

    forward_moves = [Move.single_touch(piece, source, Square.move_direction(source, advance_direction, 1), capture: :forbidden)]

    forward_moves =
      if Square.rank(source) == start_rank do
        move = Move.single_touch(piece, source, Square.move_direction(source, advance_direction, 2), capture: :forbidden)
        [move | forward_moves]
      else
        forward_moves
      end

    capture_right_dest = source |> Square.move_direction(advance_direction) |> Square.right()
    capture_left_dest = source |> Square.move_direction(advance_direction) |> Square.left()

    capture_moves = [
      Move.single_touch(piece, source, capture_right_dest, capture: :required, captures: capture_right_dest),
      Move.single_touch(piece, source, capture_left_dest, capture: :required, captures: capture_left_dest)
    ]

    en_passant_moves = [
      Move.single_touch(piece, source, capture_right_dest, capture: :required, captures: Square.right(source), capture_piece_type: :pawn),
      Move.single_touch(piece, source, capture_left_dest, capture: :required, captures: Square.left(source), capture_piece_type: :pawn)
    ]

    en_passant_capture_rank =
      case player do
        :white -> 5
        :black -> 4
      end

    moves =
      if Square.rank(source) == en_passant_capture_rank do
        forward_moves ++ capture_moves ++ en_passant_moves
      else
        forward_moves ++ capture_moves
      end

    moves
    |> Enum.flat_map(fn move ->
      upgrade_move_to_pawn_promotions(move)
    end)
  end

  defp possible_pawn_sources(player, destination) do
    moves =
      possible_pawn_captures(player, destination) ++ possible_pawn_advances(player, destination)

    Enum.flat_map(moves, fn move ->
      upgrade_move_to_pawn_promotions(move)
    end)
  end

  defp upgrade_move_to_pawn_promotions(move) do
    if [touch] = move.movements do
      if touch.piece.type == :pawn do
        can_promote? =
          case {touch.piece.color, Square.rank(touch.destination)} do
            {:white, 8} -> true
            {:white, _} -> false
            {:black, 1} -> true
            {:black, _} -> false
          end

        if can_promote? do
          promotions =
            Enum.map([:queen, :rook, :bishop, :knight], fn piece_type ->
              %Promotion{
                source: touch.destination,
                promoted_to: Piece.new(piece_type, touch.piece.color)
              }
            end)

          Enum.map(promotions, fn promotion ->
            %{move | movements: move.movements ++ [promotion]}
          end)
        else
          [move]
        end
      else
        [move]
      end
    else
      [move]
    end
  end

  defp possible_pawn_captures(player, destination) do
    ep_captured_square =
      case player do
        :white -> Square.down(destination)
        :black -> Square.up(destination)
      end

    sources =
      [Square.left(ep_captured_square), Square.right(ep_captured_square)]

    # Most recent move was to current pos
    required_history_fn = fn history ->
      captured_pawn_last_moved_to_this_square? =
        Enum.at(history, 0) == Square.to_algebraic(ep_captured_square)

      # captured pawn's previous move was two squares
      captured_pawn_didnt_move_previously? =
        Enum.take_every(history, 2)
        |> Enum.all?(fn move ->
          forbidden_square =
            case player do
              :white -> Square.down(ep_captured_square)
              :black -> Square.up(ep_captured_square)
            end
          move != Square.to_algebraic(forbidden_square)
        end)

      captured_pawn_last_moved_to_this_square? and
        captured_pawn_didnt_move_previously?
    end

    # capturing pawn must have advanced exactly three ranks
    capturing_pawn_advanced_exactly_three_ranks? =
      case player do
        :white -> ep_captured_square.rank == 5
        :black -> ep_captured_square.rank == 4
      end

    en_passant_moves =
      sources
      |> Enum.map(fn source ->
        Move.new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, player))],
          capture: :required,
          captures: ep_captured_square,
          captured_piece_type: :pawn,
          match_history_fn: required_history_fn
        })
      end)

    regular_moves =
      sources
      |> Enum.map(fn source ->
        Move.new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, player))],
          capture: :required,
          captures: destination
        })
      end)

    if capturing_pawn_advanced_exactly_three_ranks? do
      en_passant_moves ++ regular_moves
    else
      regular_moves
    end
  end

  defp possible_pawn_advances(player, destination) do
    rank = Square.rank(destination)

    can_move_two? =
      case {player, rank} do
        {:white, 4} -> true
        {:white, _} -> false
        {:black, 5} -> true
        {:black, _} -> false
      end

    move_one_source =
      case player do
        :white -> Square.down(destination, 1)
        :black -> Square.up(destination, 1)
      end

    move_one =
      Move.single_touch(Piece.new(:pawn, player), move_one_source, destination, capture: :forbidden)

    move_two_source =
      case player do
        :white -> Square.down(destination, 2)
        :black -> Square.up(destination, 2)
      end

    move_two =
      Move.single_touch(Piece.new(:pawn, player), move_two_source, destination, capture: :forbidden)

    cond do
      can_move_two? -> [move_one, move_two]
      true -> [move_one]
    end
  end

  defp possible_king_moves(player, source) do
    king_movements(source)
    |> Enum.map(fn destination ->
      Move.single_touch(Piece.new(:king, player), source, destination)
    end)
  end

  defp possible_king_sources(player, destination) do
    king_movements(destination)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:king, player), source, destination)
    end)
  end

  defp king_movements(source) do
    for distance <- [1], direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defp possible_queen_moves(player, source) do
    queen_movements(source)
    |> Enum.map(fn destination ->
      Move.single_touch(Piece.new(:queen, player), source, destination)
    end)
  end

  defp possible_queen_sources(player, destination) do
    queen_movements(destination)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:queen, player), source, destination)
    end)
  end

  defp queen_movements(source) do
    for distance <- 1..7, direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defp possible_rook_moves(player, source) do
    rook_movements(source)
    |> Enum.map(fn destination ->
      Move.single_touch(Piece.new(:rook, player), source, destination)
    end)
  end

  defp possible_rook_sources(player, destination) do
    rook_movements(destination)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:rook, player), source, destination)
    end)
  end

  defp rook_movements(around) do
    for distance <- 1..7, direction <- [:up, :left, :down, :right] do
      Square.move_direction(around, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defp possible_bishop_moves(player, source) do
    bishop_movements(source)
    |> Enum.map(fn destination ->
      Move.single_touch(Piece.new(:bishop, player), source, destination)
    end)
  end

  defp possible_bishop_sources(player, destination) do
    bishop_movements(destination)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:bishop, player), source, destination)
    end)
  end

  defp bishop_movements(around) do
    for distance <- 1..7, direction <- [:up_right, :down_right, :down_left, :up_left] do
      Square.move_direction(around, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defp possible_knight_moves(player, source) do
    knight_movements(source)
    |> Enum.map(fn destination ->
      Move.single_touch(Piece.new(:knight, player), source, destination, traverses: false)
    end)
  end

  defp possible_knight_sources(player, destination) do
    knight_movements(destination)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:knight, player), source, destination, traverses: false)
    end)
  end

  defp knight_movements(around) do
    [
      around |> Square.up(2) |> Square.right(),
      around |> Square.up(2) |> Square.left(),
      around |> Square.right(2) |> Square.up(),
      around |> Square.right(2) |> Square.down(),
      around |> Square.down(2) |> Square.right(),
      around |> Square.down(2) |> Square.left(),
      around |> Square.left(2) |> Square.up(),
      around |> Square.left(2) |> Square.down()
    ]
    |> Enum.filter(fn source ->
      Square.within?(source, 1..8, 1..8)
    end)
  end
end
