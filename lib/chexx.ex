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

  def delete_piece(board, square) do
    Map.update!(board, :pieces, fn pieces ->
      Enum.reject(pieces, fn piece ->
        piece.square == square
      end)
    end)
  end

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

    %{
      moved_piece_type: moved_piece,
      destination: {dest_file, dest_rank},
      capture?: Map.get(captures, "capture_flag") == "x",
      source_file: source_file,
      source_rank: source_rank
    }
  end

  def move(board, by, notation) do
    case notation do
      "0-0" -> kingside_castle(board, by, notation)
      "0-0-0" -> queenside_castle(board, by, notation)
      notation -> simple_move(board, by, notation)
    end
  end

  defp kingside_castle(board, by, notation) do
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

    board
    |> move_piece(king_start_pos, king_dest_pos, expect_type: :king, expect_color: by)
    |> move_piece(rook_start_pos, rook_dest_pos, expect_type: :rook, expect_color: by)
    |> put_move(notation)
  end

  defp queenside_castle(board, by, notation) do
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

    if piece_at(board, traversed_square) do
      raise "Can't queenside castle, the intervening square #{inspect traversed_square} is occupied."
    end
    
    board
    |> move_piece(king_start_pos, king_dest_pos, expect_type: :king, expect_color: by)
    |> move_piece(rook_start_pos, rook_dest_pos, expect_type: :rook, expect_color: by)
    |> put_move(notation)
  end

  def piece_equals?(piece, color, type) do
    not is_nil(piece) and piece.color == color and piece.type == type
  end

  defp simple_move(board, by, notation) do
    %{
      moved_piece_type: piece_type_moved,
      destination: destination,
      capture?: is_capture?
    } = move = parse_notation(notation)

    {possible_starting_positions, is_en_passant_capture?} =
      case piece_type_moved do
        :pawn -> possible_pawn_sources(board, by, move)
        :king -> {possible_king_sources(destination), false}
        :rook -> {possible_rook_sources(destination), false}
      end

    possible_source_spaces =
      possible_starting_positions
      |> Enum.filter(fn possible_starting_position ->
        possible_moved_piece = piece_at(board, possible_starting_position)

        not is_nil(possible_moved_piece) and
          possible_moved_piece.color == by and
          possible_moved_piece.type == piece_type_moved
      end)

    if Enum.empty?(possible_source_spaces) do
      raise "No piece found for #{by} to perform move #{inspect notation}. Board: #{inspect board}"
    end

    possible_source_count = Enum.count(possible_source_spaces)
    if possible_source_count > 1 do
      raise "Ambiguous move: #{inspect notation} can mean #{possible_source_count} possible moves. Possible source spaces: #{inspect possible_source_spaces}"
    end

    source_space = Enum.at(possible_source_spaces, 0)

    capture_type =
      if is_en_passant_capture? do
        case by do
          :white -> down(destination)
          :black -> up(destination)
        end
      else
        if is_capture? do
          :required
        else
          :forbidden
        end
      end

    board
    |> move_piece(
        source_space,
        destination,
        expect_type: piece_type_moved,
        expect_color: by,
        capture: capture_type
      )
    |> put_move(notation)
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

    capture = Keyword.get(opts, :capture, :forbidden)

    captured_square =
      case capture do
        :required -> dest
        :allowed -> dest
        {file, rank} when is_file(file) and is_rank(rank) -> {file, rank}
        :forbidden -> nil
      end

    board =
      if is_nil(captured_square) do
        board
      else
        captured_piece = piece_at(board, captured_square)

        if capture == :required and is_nil(captured_piece) do
          raise "Move requires the destination be captured but there is no piece there."
        end

        if is_valid_square(capture) and is_nil(captured_piece) do
          raise "Move requires the piece at #{inspect captured_square} be captured but there is no piece there."
        end

        if not is_nil(captured_piece) and captured_piece.color == piece.color do
          raise "A piece cannot capture its own color."
        end

        delete_piece(board, captured_square)
      end

    board
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

  defp possible_pawn_sources(board, by, move) do
    %{
      destination: destination,
      capture?: is_capture?,
      source_file: source_file
      } = move

    if is_capture? do
      {_file, destination_rank} = destination

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

      piece_in_en_passant_capture_square = piece_at(board, en_passant_captured_square)

      # Most recent move was to current pos
      captured_pawn_last_moved_to_this_square? =
        Enum.at(board.history, 0) == "#{to_string(en_passant_captured_file)}#{to_string(en_passant_captured_rank)}"

      # captured pawn's previous move was two squares
      captured_pawn_didnt_move_previously? =
        Enum.take_every(board.history, 2)
        |> Enum.all?(fn move ->
          {forbidden_file, forbidden_rank} =
            case by do
              :white -> down(en_passant_captured_square)
              :black -> up(en_passant_captured_square)
            end
          move != "#{to_string(forbidden_file)}#{to_string(forbidden_rank)}"
        end)

      # capturing pawn must have advanced exactly three ranks
      capturing_pawn_advanced_exactly_three_ranks? =
        case by do
          :white -> source_rank == 5
          :black -> source_rank == 4
        end

      en_passant_capture? =
        not is_nil(piece_in_en_passant_capture_square) and
        is_nil(piece_at(board, destination)) and
        piece_in_en_passant_capture_square.type == :pawn and
        captured_pawn_last_moved_to_this_square? and
        captured_pawn_didnt_move_previously? and
        capturing_pawn_advanced_exactly_three_ranks?

      regular_capture? =
        not is_nil(piece_at(board, destination))

      if regular_capture? or en_passant_capture? do
        {[source], en_passant_capture?}
      else
        {[], false}
      end
    else
      {_file, rank} = destination

      can_move_one? = is_nil(piece_at(board, destination))

      can_move_two? =
        can_move_one? and
          case {by, rank} do
            {:white, 4} ->
                is_nil(piece_at(board, down(destination, 1)))
            {:white, _} -> false
            {:black, 5} ->
                is_nil(piece_at(board, up(destination, 1)))
            {:black, _} -> false
          end

      move_one =
        case by do
          :white -> down(destination, 1)
          :black -> up(destination, 1)
        end

      move_two =
        case by do
          :white -> down(destination, 2)
          :black -> up(destination, 2)
        end

      allowed_moves =
        cond do
          can_move_two? -> [move_one, move_two]
          can_move_one? -> [move_one]
          true -> []
        end

      {allowed_moves, false}
    end
  end

  defp possible_king_sources(destination) do
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
  end

  defp possible_rook_sources(destination) do
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
  end
end
