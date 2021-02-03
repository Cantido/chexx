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

  defp is_valid_square({file, rank}) do
    file in [:a, :b, :c, :d, :e, :f, :g, :h] and rank in 1..8
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
    %{
      moved_piece_type: piece_type_moved,
      destination: destination,
      capture?: is_capture?
    } = move = parse_notation(notation)

    {possible_starting_positions, is_en_passant_capture?} =
      case piece_type_moved do
        :pawn -> possible_pawn_sources(board, by, move)
        :king -> {possible_king_sources(destination), false}
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

    moving_piece = piece_at(board, source_space)

    captured_square =
      if is_en_passant_capture? do
        case by do
          :white -> down(destination)
          :black -> up(destination)
        end
      else
        destination
      end

    if moving_piece.color != by do
      raise "Cannot move the other player's pieces."
    end

    captured_piece = piece_at(board, captured_square)

    if not is_nil(captured_piece) and captured_piece.color == by do
      raise "Cannot capture your own piece!"
    end

    piece_at_captured_square? = not is_nil(captured_piece)
    unexpected_capture_flag = is_capture? and not piece_at_captured_square?
    missing_capture_flag = piece_at_captured_square? and not is_capture?

    if unexpected_capture_flag do
      raise "Move #{notation} indicated a capture at #{inspect destination}, but there is no piece there."
    end

    if missing_capture_flag do
      raise "Move #{notation} indicated no capture at #{inspect destination}, but there is a piece there."
    end

    board
    |> delete_piece(source_space)
    |> delete_piece(captured_square)
    |> put_piece(moving_piece.type, moving_piece.color, destination)
    |> put_move(notation)
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

  defp file_to_number(:a), do: 1
  defp file_to_number(:b), do: 2
  defp file_to_number(:c), do: 3
  defp file_to_number(:d), do: 4
  defp file_to_number(:e), do: 5
  defp file_to_number(:f), do: 6
  defp file_to_number(:g), do: 7
  defp file_to_number(:h), do: 8

  defp number_to_file(1), do: :a
  defp number_to_file(2), do: :b
  defp number_to_file(3), do: :c
  defp number_to_file(4), do: :d
  defp number_to_file(5), do: :e
  defp number_to_file(6), do: :f
  defp number_to_file(7), do: :g
  defp number_to_file(8), do: :h

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
end
