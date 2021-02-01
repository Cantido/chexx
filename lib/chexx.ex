defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  def new do
    %{history: [], pieces: []}
  end

  def put_piece(board, type, color, square) do
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

  @pawn_notation ~r/^[a-h][1-8]$/
  @pawn_capture_notation ~r/^[a-h]x[a-h][1-8]$/

  def move(board, by, movement) do
    {piece_type_moved, destination, possible_starting_positions, is_en_passant_capture?} =
      cond do
        String.match?(movement, @pawn_notation) ->
          file = String.at(movement, 0) |> String.to_existing_atom()
          {rank, ""} = String.at(movement, 1) |> Integer.parse()
          destination = {file, rank}

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

            {:pawn, destination, allowed_moves, false}
        String.match?(movement, @pawn_capture_notation) ->
          file = String.at(movement, 2) |> String.to_existing_atom()
          {destination_rank, ""} = String.at(movement, 3) |> Integer.parse()
          destination = {file, destination_rank}

          starting_file = String.at(movement, 0) |> String.to_existing_atom()
          {_source_file, source_rank} = source =
            case by do
              :white -> down({starting_file, destination_rank}, 1)
              :black -> up({starting_file, destination_rank}, 1)
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
            {:pawn, destination, [source], en_passant_capture?}
          else
            {:pawn, destination, [], false}
          end
        true ->
          raise "Move #{inspect movement} not recognized"
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
      raise "No piece found for #{by} to perform move #{inspect movement}"
    end

    possible_source_count = Enum.count(possible_source_spaces)
    if possible_source_count > 1 do
      raise "Ambiguous move: #{inspect movement} can mean #{possible_source_count} possible moves. Possible source spaces: #{inspect possible_source_spaces}"
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

    board
    |> delete_piece(source_space)
    |> delete_piece(captured_square)
    |> put_piece(moving_piece.type, moving_piece.color, destination)
    |> put_move(movement)
  end

  def up({file, rank}, squares \\ 1) do
    {file, rank + squares}
  end

  def down({file, rank}, squares \\ 1) do
    {file, rank - squares}
  end

  def left({file, rank}, squares) do
    new_file = number_to_file(file_to_number(file) - squares)
    {new_file, rank}
  end

  def right({file, rank}, squares) do
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
