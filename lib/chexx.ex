defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  alias Chexx.Square
  alias Chexx.Board
  alias Chexx.Piece
  alias Chexx.Move
  alias Chexx.Touch

  import Chexx.Square, only: [is_file: 1]

  defstruct [
    history: [],
    board: Board.new()
  ]

  # TODO: validate when the check or checkmate symbol appears
  # TODO: don't let a piece move to its own position, i.e. not actually move

  def new do
    %__MODULE__{}
  end

  def new(%Board{} = board) do
    %__MODULE__{board: board}
  end

  def put_piece(game, type, color, square) do
    %__MODULE__{game | board: Board.put_piece(game.board, type, color, Square.new(square))}
  end

  def piece_at(game, square) do
    Board.piece_at(game.board, Square.new(square))
  end

  defp put_move(game, move) do
    Map.update!(game, :history, fn history ->
      [move | history]
    end)
  end

  @notation_regex ~r/^(?<moved_piece>[KQRBNp]?)(?<source_file>[a-h]?)(?<source_rank>[1-8]?)(?<capture_flag>x?)(?<dest_file>[a-h])(?<dest_rank>[1-8])$/

  defp parse_notation(notation) do
    unless String.match?(notation, @notation_regex) do
      raise "Notation #{inspect notation} not recognized"
    end

    captures = Regex.named_captures(@notation_regex, notation)

    moved_piece =
      case Map.get(captures, "moved_piece") do
        "K" -> :king
        "Q" -> :queen
        "R" -> :rook
        "B" -> :bishop
        "N" -> :knight
        "p" -> :pawn
        "" -> :pawn
      end

    dest_file = captures["dest_file"] |> String.to_existing_atom()
    {dest_rank, ""} = captures["dest_rank"] |> Integer.parse()

    source_file_notation = Map.get(captures, "source_file")
    source_file =
      if source_file_notation == "" do
        nil
      else
        String.to_existing_atom(source_file_notation)
      end

    source_rank_notation = Map.get(captures, "source_rank")
    source_rank =
      if source_rank_notation == "" do
        nil
      else
        String.to_existing_atom(source_rank_notation)
      end

    source =
      cond do
        not is_nil(source_file) and not is_nil(source_rank) -> Square.new(source_file, source_rank)
        not is_nil(source_file) -> source_file
        true -> nil
      end

    capture_type =
      if Map.get(captures, "capture_flag") == "x" do
        :required
      else
        :forbidden
      end

    %{
      piece_type: moved_piece,
      source: source,
      destination: Square.new(dest_file, dest_rank),
      capture: capture_type
    }
  end

  def move(game, by, notation) do
    move =
      possible_moves(notation, by)
      |> disambiguate_moves(game, by)

    board = Board.move(game.board, by, move)

    game = put_move(game, notation)

    %{game | board: board}
  end

  defp possible_moves(notation, player) do
    case notation do
      "0-0" -> kingside_castle(player)
      "0-0-0" -> queenside_castle(player)
      notation ->
        notation = parse_notation(notation)

        case notation.piece_type do
          :pawn -> possible_pawn_sources(player, notation)
          :king -> possible_king_sources(player, notation.destination)
          :rook -> possible_rook_sources(player, notation.destination)
        end
    end
  end

  defp disambiguate_moves(moves, game, by) do
    moves =
      moves
      |> Enum.filter(fn possible_move ->
        Enum.all?(possible_move.movements, fn %{source: src, piece: expected_piece} ->
          actual_piece = Board.piece_at(game.board, src)

          expected_piece.color == by and expected_piece == actual_piece
        end)
      end)
      |> Enum.reject(fn possible_move ->
        Map.get(possible_move, :traverses, [])
        |> Enum.any?(fn traversed_square ->
          Board.piece_at(game.board, traversed_square)
        end)
      end)
      |> Enum.reject(fn possible_move ->
        capture = Map.get(possible_move, :capture, :forbidden)
        captured_square = Map.get(possible_move, :captures)
        captured_piece = Board.piece_at(game.board, captured_square)

        capture == :required and
          (is_nil(captured_piece) or captured_piece.color == by)
      end)
      |> Enum.filter(fn possible_move ->
        match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

        match_history_fn.(game.history)
      end)

    if Enum.empty?(moves) do
      raise "No valid moves found for #{by}."
    end

    possible_moves_count = Enum.count(moves)
    if possible_moves_count > 1 do
      raise "Ambiguous move: notation can mean #{possible_moves_count} possible moves."
    end

    Enum.at(moves, 0)
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

  defp possible_pawn_sources(by, move) do
    %{
      source: source,
      destination: destination,
      capture: capture_type
      } = move

    {destination_file, destination_rank} = Square.coords(destination)

    source_file =
      cond do
        is_nil(source) -> Square.file(destination)
        is_file(source) -> source
        true -> Square.file(source)
      end

    is_capture? = capture_type == :required or destination_file != source_file

    if is_capture? do
      source =
        case by do
          :white -> Square.new(source_file, destination_rank) |> Square.down(1)
          :black -> Square.new(source_file, destination_rank) |> Square.up(1)
        end

      en_passant_captured_square =
        case by do
          :white -> Square.down(destination)
          :black -> Square.up(destination)
        end

      # Most recent move was to current pos


      required_history_fn = fn history ->
        captured_pawn_last_moved_to_this_square? =
          Enum.at(history, 0) == Square.to_algebraic(en_passant_captured_square)

        # captured pawn's previous move was two squares
        captured_pawn_didnt_move_previously? =
          Enum.take_every(history, 2)
          |> Enum.all?(fn move ->
            forbidden_square =
              case by do
                :white -> Square.down(en_passant_captured_square)
                :black -> Square.up(en_passant_captured_square)
              end
            move != Square.to_algebraic(forbidden_square)
          end)

        captured_pawn_last_moved_to_this_square? and
          captured_pawn_didnt_move_previously?
      end

      # capturing pawn must have advanced exactly three ranks
      capturing_pawn_advanced_exactly_three_ranks? =
        case by do
          :white -> source.rank == 5
          :black -> source.rank == 4
        end

      en_passant_move =
        Move.new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, by))],
          capture: :required,
          captures: en_passant_captured_square,
          captured_piece_type: :pawn,
          match_history_fn: required_history_fn
        })

      regular_move =
        Move.new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, by))],
          capture: :required,
          captures: destination,
          captured_piece_type: :pawn
        })

      if capturing_pawn_advanced_exactly_three_ranks? do
        [en_passant_move]
      else
        [regular_move]
      end
    else
      rank = Square.rank(destination)

      can_move_two? =
        case {by, rank} do
          {:white, 4} -> true
          {:white, _} -> false
          {:black, 5} -> true
          {:black, _} -> false
        end

      move_one_source =
        case by do
          :white -> Square.down(destination, 1)
          :black -> Square.up(destination, 1)
        end

      move_one =
        Move.new(%{
          movements: [
            Touch.new(move_one_source, destination, Piece.new(:pawn, by))
          ]
        })

      move_two_source =
        case by do
          :white -> Square.down(destination, 2)
          :black -> Square.up(destination, 2)
        end

      move_two =
        Move.new(%{
          movements: [
            Touch.new(move_two_source, destination, Piece.new(:pawn, by))
          ],
          traverses: Square.squares_between(move_two_source, destination)
        })

      cond do
        can_move_two? -> [move_one, move_two]
        true -> [move_one]
      end
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
      Move.new(%{
        movements: [Touch.new(source, destination, Piece.new(:king, player))],
        capture: :allowed,
        captures: destination
      })
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
      Move.new(%{
        movements: [Touch.new(source, destination, Piece.new(:rook, player))],
        traverses: Square.squares_between(source, destination),
        capture: :allowed,
        captures: destination
      })
    end)
  end
end
