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

  import Chexx.Color

  defstruct [
    history: [],
    current_player: :white,
    board: Board.new(),
  ]

  # TODO: validate when the check or checkmate symbol appears
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

  def move(game, notation) do
    parsed_notation =  AlgebraicNotation.parse(notation)
    move =
      possible_moves(parsed_notation, game.current_player)
      |> disambiguate_moves(game, game.current_player, parsed_notation)

    board = Board.move(game.board, move)
    opponent = Color.opponent(game.current_player)

    game = put_move(game, notation)

    %{game | board: board, current_player: opponent}
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
    moves =
      moves
      |> Enum.filter(&Board.valid_move?(game.board, by, &1))
      |> Enum.filter(fn possible_move ->
        match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)
      |> Enum.filter(fn move ->
        board = Board.move(game.board, move)
        results_in_check? = king_in_check?(%{game | board: board}, Color.opponent(by))

        expected_check = parsed_notation.check?

        not xor(expected_check, results_in_check?)
      end)
      |> Enum.reject(fn possible_move ->
        board = Board.move(game.board, possible_move)
        king_in_check?(%{game | board: board}, by)
      end)

    if Enum.empty?(moves) do
      raise "No valid moves found for #{by}."
    end


    possible_moves_count = Enum.count(moves)
    if possible_moves_count > 1 do
      raise "Ambiguous move: notation can mean #{possible_moves_count} possible moves: #{inspect moves}"
    end

    Enum.at(moves, 0)
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

  defp possible_pawn_sources(by, destination) do
    possible_pawn_captures(by, destination) ++ possible_pawn_advances(by, destination)
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
      Move.single_touch(Piece.new(:pawn, player), move_one_source, destination)

    move_two_source =
      case player do
        :white -> Square.down(destination, 2)
        :black -> Square.up(destination, 2)
      end

    move_two =
      Move.single_touch(Piece.new(:pawn, player), move_two_source, destination)

    cond do
      can_move_two? -> [move_one, move_two]
      true -> [move_one]
    end
  end

  defp possible_king_sources(player, destination) do
    for distance <- [1], direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(destination, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:king, player), source, destination)
    end)
  end

  defp possible_queen_sources(player, destination) do
    for distance <- 1..7, direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(destination, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:queen, player), source, destination)
    end)
  end

  defp possible_rook_sources(player, destination) do
    for distance <- 1..7, direction <- [:up, :left, :down, :right] do
      Square.move_direction(destination, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:rook, player), source, destination)
    end)
  end

  defp possible_bishop_sources(player, destination) do
    for distance <- 1..7, direction <- [:up_right, :down_right, :down_left, :up_left] do
      Square.move_direction(destination, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:bishop, player), source, destination)
    end)
  end

  defp possible_knight_sources(player, destination) do
    [
      destination |> Square.up(2) |> Square.right(),
      destination |> Square.up(2) |> Square.left(),
      destination |> Square.right(2) |> Square.up(),
      destination |> Square.right(2) |> Square.down(),
      destination |> Square.down(2) |> Square.right(),
      destination |> Square.down(2) |> Square.left(),
      destination |> Square.left(2) |> Square.up(),
      destination |> Square.left(2) |> Square.down()
    ]
    |> Enum.filter(fn source ->
      Square.within?(source, 1..8, 1..8)
    end)
    |> Enum.map(fn source ->
      Move.single_touch(Piece.new(:knight, player), source, destination, traverses: false)
    end)
  end
end
