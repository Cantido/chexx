defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  def new do
    []
  end

  def put_piece(board, type, color, square) do
    if not is_nil(piece_at(board, square)) do
      raise "That square already has a piece"
    end

    if not is_valid_square(square) do
      raise "Not a valid place to put a piece"
    end

    [%{type: type, color: color, square: square} | board]
  end

  defp is_valid_square({file, rank}) do
    file in [:a, :b, :c, :d, :e, :f, :g, :h] and rank in 1..8
  end

  def delete_piece(board, square) do
    Enum.reject(board, fn piece ->
      piece.square == square
    end)
  end

  def piece_at(board, square) do
    board
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
            {:black, 4} -> [up(destination, 1), up(destination, 2)]
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

    board
    |> delete_piece(source_space)
    |> delete_piece(destination)
    |> put_piece(moving_piece.type, moving_piece.color, destination)
  end

  defp up({file, rank}, squares) do
    {file, rank + squares}
  end

  defp down({file, rank}, squares) do
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
