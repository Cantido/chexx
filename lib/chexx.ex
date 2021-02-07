defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  # TODO: validate when the check or checkmate symbol appears
  # TODO: don't let a piece move to its own position, i.e. not actually move

  defguard is_color(color) when color == :black or color == :white
  defguard is_piece(piece) when
    piece == :king or
    piece == :queen or
    piece == :rook or
    piece == :bishop or
    piece == :knight or
    piece == :pawn

  defguard is_file(file) when file in [:a, :b, :c, :d, :e, :f, :g, :h]
  defguard is_rank(rank) when rank in 1..8

  def is_valid_square({file, rank}) when is_file(file) and is_rank(rank), do: true
  def is_valid_square(_), do: false

  def new do
    %{history: [], pieces: []}
  end

  def put_piece(board, type, color, square) when is_piece(type) and is_color(color) do
    if piece = piece_at(board, square) do
      raise "Square #{inspect(square)} square already has piece #{inspect(piece)}."
    end

    if not is_valid_square(square) do
      raise "Square #{inspect(square)}is not a valid place to put a piece"
    end

    pieces = [%{type: type, color: color, square: square} | board.pieces]
    %{board | pieces: pieces}
  end

  defp put_move(board, move) do
    Map.update!(board, :history, fn history ->
      [move | history]
    end)
  end

  def delete_piece(board, square) when is_nil(square), do: board

  def delete_piece(board, square) do
    Map.update!(board, :pieces, fn pieces ->
      Enum.reject(pieces, fn piece ->
        piece.square == square
      end)
    end)
  end

  def piece_at(_board, nil), do: nil

  def piece_at(board, square) do
    board.pieces
    |> Enum.find(fn piece ->
      piece.square == square
    end)
    |> case do
      nil -> nil
      piece ->
        Map.take(piece, [
          :type,
          :color
        ])
    end
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
      if is_nil(source_file) and is_nil(source_rank) do
        nil
      else
        {source_file, source_rank}
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
      destination: {dest_file, dest_rank},
      capture: capture_type
    }
  end

  def move(board, by, notation) do
    moves =
      case notation do
        "0-0" -> kingside_castle(by)
        "0-0-0" -> queenside_castle(by)
        notation ->
          move = parse_notation(notation)

          case move.piece_type do
            :pawn -> possible_pawn_sources(by, move)
            :king -> possible_king_sources(by, move.destination)
            :rook -> possible_rook_sources(by, move.destination)
          end
      end

    moves =
      moves
      |> Enum.filter(fn possible_move ->
        Enum.all?(possible_move.movements, fn %{source: src, piece_type: piece_type, piece_color: piece_color} ->
          src_piece = piece_at(board, src)

          piece_color == by and
            piece_equals?(src_piece, piece_color, piece_type)
        end)
      end)
      |> Enum.reject(fn possible_move ->
        Map.get(possible_move, :traverses, [])
        |> Enum.any?(fn traversed_square ->
          piece_at(board, traversed_square)
        end)
      end)
      |> Enum.reject(fn possible_move ->
        capture = Map.get(possible_move, :capture, :forbidden)
        captured_square = Map.get(possible_move, :captures)
        captured_piece = piece_at(board, captured_square)

        capture == :required and
          (is_nil(captured_piece) or captured_piece.color == by)
      end)
      |> Enum.filter(fn possible_move ->
        match_history_fn = Map.get(possible_move, :match_history_fn, fn _ -> true end)

        match_history_fn.(board.history)
      end)

    if Enum.empty?(moves) do
      raise "No valid moves found for #{by}."
    end

    possible_moves_count = Enum.count(moves)
    if possible_moves_count > 1 do
      raise "Ambiguous move: #{inspect notation} can mean #{possible_moves_count} possible moves. Possible source spaces: #{inspect moves}"
    end

    move = Enum.at(moves, 0)

    board
    |> do_move(by, move)
    |> put_move(notation)
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
        :white -> {:e, 1}
        :black -> {:e, 8}
      end

    king_dest_pos =
      case by do
        :white -> {:g, 1}
        :black -> {:g, 8}
      end

    rook_start_pos =
      case by do
        :white -> {:h, 1}
        :black -> {:h, 8}
      end

    rook_dest_pos =
      case by do
        :white -> {:f, 1}
        :black -> {:f, 8}
      end

    [%{
      movements: [
        %{piece_type: :king, piece_color: by, source: king_start_pos, destination: king_dest_pos},
        %{piece_type: :rook, piece_color: by, source: rook_start_pos, destination: rook_dest_pos},
      ],
      match_history_fn: match_history_fn
    }]
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
        :white -> {:e, 1}
        :black -> {:e, 8}
      end

    king_dest_pos =
      case by do
        :white -> {:c, 1}
        :black -> {:c, 8}
      end

    rook_start_pos =
      case by do
        :white -> {:a, 1}
        :black -> {:a, 8}
      end

    rook_dest_pos =
      case by do
        :white -> {:d, 1}
        :black -> {:d, 8}
      end

    traversed_square =
      case by do
        :white -> {:b, 1}
        :black -> {:b, 8}
      end

    [%{
      movements: [
        %{piece_type: :king, piece_color: by, source: king_start_pos, destination: king_dest_pos},
        %{piece_type: :rook, piece_color: by, source: rook_start_pos, destination: rook_dest_pos},
      ],
      traverses: [traversed_square],
      match_history_fn: match_history_fn
    }]
  end

  def piece_equals?(piece, color, type) do
    not is_nil(piece) and piece.color == color and piece.type == type
  end

  defp do_move(board, by, move) do
    Enum.reduce(move.movements, board, fn %{source: src, destination: dest, piece_type: piece_type}, board ->
      move_piece(board, src, dest, captures: Map.get(move, :captures), expect_type: piece_type, expect_color: by)
    end)
  end

  def move_piece(board, source, dest, opts \\ []) do
    piece = piece_at(board, source)

    if is_nil(piece) do
      raise "No piece at #{inspect source} to move."
    end

    if type = Keyword.get(opts, :expect_type) do
      if type != piece.type do
        raise "Expected a #{type} to be at #{inspect source}, but it was a #{piece.type} instead."
      end
    end

    if color = Keyword.get(opts, :expect_color) do
      if color != piece.color do
        raise "Expected a #{color} piece at #{inspect source}, but it was a #{piece.color} piece."
      end
    end

    captured_square = Keyword.get(opts, :captures)

    board
    |> delete_piece(captured_square)
    |> delete_piece(source)
    |> put_piece(piece.type, piece.color, dest)
  end

  def move_direction(square, direction, distance \\ 1) do
    case direction do
      :up -> up(square, distance)
      :up_right -> up_right(square, distance)
      :right -> right(square, distance)
      :down_right -> down_right(square, distance)
      :down -> down(square, distance)
      :down_left -> down_left(square, distance)
      :left -> left(square, distance)
      :up_left -> up_left(square, distance)
    end
  end

  def up({file, rank}, squares \\ 1) do
    {file, rank + squares}
  end

  def up_right(start, distance \\ 1) do
    start
    |> up(distance)
    |> right(distance)
  end

  def right({file, rank}, squares \\ 1) do
    new_file = number_to_file(file_to_number(file) + squares)
    {new_file, rank}
  end

  def down_right(start, distance \\ 1) do
    start
    |> down(distance)
    |> right(distance)
  end

  def down({file, rank}, squares \\ 1) do
    {file, rank - squares}
  end

  def down_left(start, distance \\ 1) do
    start
    |> down(distance)
    |> left(distance)
  end

  def left({file, rank}, squares \\ 1) do
    new_file = number_to_file(file_to_number(file) - squares)
    {new_file, rank}
  end

  def up_left(start, distance \\ 1) do
    start
    |> up(distance)
    |> left(distance)
  end

  def file_to_number(:a), do: 1
  def file_to_number(:b), do: 2
  def file_to_number(:c), do: 3
  def file_to_number(:d), do: 4
  def file_to_number(:e), do: 5
  def file_to_number(:f), do: 6
  def file_to_number(:g), do: 7
  def file_to_number(:h), do: 8

  def file_to_number(1), do: 1
  def file_to_number(2), do: 2
  def file_to_number(3), do: 3
  def file_to_number(4), do: 4
  def file_to_number(5), do: 5
  def file_to_number(6), do: 6
  def file_to_number(7), do: 7
  def file_to_number(8), do: 8

  def number_to_file(1), do: :a
  def number_to_file(2), do: :b
  def number_to_file(3), do: :c
  def number_to_file(4), do: :d
  def number_to_file(5), do: :e
  def number_to_file(6), do: :f
  def number_to_file(7), do: :g
  def number_to_file(8), do: :h

  require Logger

  defp possible_pawn_sources(by, move) do
    %{
      source: source,
      destination: destination,
      capture: capture_type
      } = move

    {destination_file, destination_rank} = destination

    source_file =
      if is_nil(source) do
        elem(destination, 0)
      else
        elem(source, 0)
      end

    Logger.info("Capture type is #{capture_type}")

    is_capture? = capture_type == :required or destination_file != source_file

    if is_capture? do
      {_source_file, source_rank} = source =
        case by do
          :white -> down({source_file, destination_rank}, 1)
          :black -> up({source_file, destination_rank}, 1)
        end

      {en_passant_captured_file, en_passant_captured_rank} = en_passant_captured_square =
        case by do
          :white -> down(destination)
          :black -> up(destination)
        end

      # Most recent move was to current pos


      required_history_fn = fn history ->
        captured_pawn_last_moved_to_this_square? =
          Enum.at(history, 0) == "#{to_string(en_passant_captured_file)}#{to_string(en_passant_captured_rank)}"

        # captured pawn's previous move was two squares
        captured_pawn_didnt_move_previously? =
          Enum.take_every(history, 2)
          |> Enum.all?(fn move ->
            {forbidden_file, forbidden_rank} =
              case by do
                :white -> down(en_passant_captured_square)
                :black -> up(en_passant_captured_square)
              end
            move != "#{to_string(forbidden_file)}#{to_string(forbidden_rank)}"
          end)

        captured_pawn_last_moved_to_this_square? and
          captured_pawn_didnt_move_previously?
      end

      # capturing pawn must have advanced exactly three ranks
      capturing_pawn_advanced_exactly_three_ranks? =
        case by do
          :white -> source_rank == 5
          :black -> source_rank == 4
        end

      en_passant_move = %{
        movements: [%{
          piece_type: :pawn,
          piece_color: by,
          source: source,
          destination: destination
        }],
        capture: :required,
        captures: en_passant_captured_square,
        captured_piece_type: :pawn,
        match_history_fn: required_history_fn
      }

      regular_move = %{
        movements: [%{
          piece_type: :pawn,
          piece_color: by,
          source: source,
          destination: destination
        }],
        capture: :required,
        captures: destination,
        captured_piece_type: :pawn
      }

      if capturing_pawn_advanced_exactly_three_ranks? do
        [en_passant_move]
      else
        [regular_move]
      end
    else
      {_file, rank} = destination

      can_move_two? =
        case {by, rank} do
          {:white, 4} -> true
          {:white, _} -> false
          {:black, 5} -> true
          {:black, _} -> false
        end

      move_one_source =
        case by do
          :white -> down(destination, 1)
          :black -> up(destination, 1)
        end

      move_one =  %{
        movements: [
          %{
            piece_type: :pawn,
            piece_color: by,
            source: move_one_source,
            destination: destination
          }
        ]
      }

      move_two_source =
        case by do
          :white -> down(destination, 2)
          :black -> up(destination, 2)
        end

      move_two = %{
        movements: [
          %{
            piece_type: :pawn,
            piece_color: by,
            source: move_two_source,
            destination: destination
          }
        ],
        traverses: squares_between(move_two_source, destination)
      }

      cond do
        can_move_two? -> [move_one, move_two]
        true -> [move_one]
      end
    end
  end

  defp possible_king_sources(player, destination) do
    {file, rank} = destination
    file_int = file_to_number(file)

    for x <- [-1, 0, 1], y <- [-1, 0, 1] do
      {file_int + x, rank + y}
    end
    |> Enum.filter(fn {source_file, source_rank} ->
      source_rank in 1..8 and source_file in 1..8
    end)
    |> Enum.map(fn {source_file, source_rank} ->
      {number_to_file(source_file), source_rank}
    end)
    |> Enum.map(fn source ->
      %{
        movements: [%{
          piece_type: :king,
          piece_color: player,
          source: source,
          destination: destination
        }],
        capture: :allowed,
        captures: destination
      }
    end)
  end

  defp possible_rook_sources(player, destination) do
    {file, rank} = destination
    file_int = file_to_number(file)

    for distance <- 1..7, direction <- [:up, :left, :down, :right] do
      case direction do
        :up -> {file_int, rank + distance}
        :left -> {file_int - distance, rank}
        :down -> {file_int, rank - distance}
        :right -> {file_int + distance, rank}
      end
    end
    |> Enum.filter(fn {source_file, source_rank} ->
      source_rank in 1..8 and source_file in 1..8
    end)
    |> Enum.map(fn {source_file, source_rank} ->
      {number_to_file(source_file), source_rank}
    end)
    |> Enum.map(fn source ->
      %{
        movements: [%{piece_type: :rook, piece_color: player, source: source, destination: destination}],
        traverses: squares_between(source, destination),
        capture: :allowed,
        captures: destination
      }
    end)
  end

  defp squares_between({src_file, src_rank}, {dest_file, dest_rank}) do
    cond do
      src_file == dest_file ->
        for rank <- ranks_between(src_rank, dest_rank) do
          {src_file, rank}
        end
      src_rank == dest_rank ->
        for file <- files_between(src_file, dest_file) do
          {file, src_rank}
        end
    end
  end

  defp ranks_between(src_rank, dest_rank) do
    range_between(src_rank, dest_rank)
  end

  defp files_between(src_file, dest_file) do
    src_file = file_to_number(src_file)
    dest_file = file_to_number(dest_file)

    range_between(src_file, dest_file)
    |> Enum.map(&number_to_file/1)
  end

  defp range_between(first, last) do
    min_val = min(first, last)
    max_val = max(first, last)
    if max_val - min_val == 1 do
      []
    else
      range_start = min_val + 1
      range_end = max_val - 1
      range_start..range_end
    end
  end
end
