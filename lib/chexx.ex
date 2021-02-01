defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  def new do
    %{history: [], pieces: []}
  end

  def put_piece(board, type, color, square) do
    if not is_nil(piece_at(board, square)) do
      raise "That square already has a piece"
    end

    if not is_valid_square(square) do
      raise "Not a valid place to put a piece"
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

  @pawn_notation ~r/^[a-h][1-8]$/
  @pawn_capture_notation ~r/^[a-h]x[a-h][1-8]$/

  def move(board, by, movement) do
    destination =
      cond do
        String.match?(movement, @pawn_notation) ->
          file = String.at(movement, 0) |> String.to_existing_atom()
          {rank, ""} = String.at(movement, 1) |> Integer.parse()
          {file, rank}
        String.match?(movement, @pawn_capture_notation) ->
          file = String.at(movement, 2) |> String.to_existing_atom()
          {rank, ""} = String.at(movement, 3) |> Integer.parse()
          {file, rank}
      end

    possible_starting_positions =
      cond do
        String.match?(movement, @pawn_notation) ->
          {_file, rank} = destination
          case {by, rank} do
            {:white, 4} -> [down(destination, 1), down(destination, 2)]
            {:white, _} -> [down(destination, 1)]
            {:black, 5} -> [up(destination, 1), up(destination, 2)]
            {:black, _} -> [up(destination, 1)]
          end
        String.match?(movement, @pawn_capture_notation) ->
          starting_file = String.at(movement, 0) |> String.to_existing_atom()
          {_file, destination_rank} = destination
          case by do
            :white -> [down({starting_file, destination_rank}, 1)]
            :black -> [up({starting_file, destination_rank}, 1)]
          end
      end

    possible_source_spaces =
      possible_starting_positions
      |> Enum.filter(fn possible_starting_position ->
        piece_at(board, possible_starting_position)
      end)

    if Enum.empty?(possible_source_spaces) do
      raise "No piece found for #{by} to perform move #{inspect movement}"
    end

    source_space = Enum.at(possible_source_spaces, 0)
    moving_piece = piece_at(board, source_space)

    captured_piece = piece_at(board, destination)

    if not is_nil(captured_piece) and captured_piece.color == by do
      raise "Cannot capture your own piece!"
    end

    {en_passant_captured_file, en_passant_captured_rank} = en_passant_captured_square =
      case by do
        :white -> down(destination)
        :black -> up(destination)
      end

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
    {_source_file, source_rank} = source_space

    capturing_pawn_advanced_exactly_three_ranks? =
      case by do
        :white -> source_rank == 5
        :black -> source_rank == 4
      end

    is_en_passant_capture? =
      is_nil(captured_piece) and
      captured_pawn_last_moved_to_this_square? and
      captured_pawn_didnt_move_previously? and
      capturing_pawn_advanced_exactly_three_ranks?


    board =
      board
      |> delete_piece(source_space)

    board =
      if is_en_passant_capture? do


        delete_piece(board, en_passant_captured_square)
      else
        delete_piece(board, destination)
      end

    board
    |> put_piece(moving_piece.type, moving_piece.color, destination)
    |> put_move(movement)
  end

  defp up({file, rank}, squares \\ 1) do
    {file, rank + squares}
  end

  defp down({file, rank}, squares \\ 1) do
    {file, rank - squares}
  end

  defp left({file, rank}, squares) do
    new_file = number_to_file(file_to_number(file) - squares)
    {new_file, rank}
  end

  defp right({file, rank}, squares) do
    new_file = number_to_file(file_to_number(file) + squares)
    {new_file, rank}
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
end
