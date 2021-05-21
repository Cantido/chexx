defmodule Chexx do
  @moduledoc """
  Documentation for `Chexx`.
  """

  alias Chexx.AlgebraicNotation
  alias Chexx.Match
  alias Chexx.Move

  def start_game do
    Match.new()
  end

  def play_board(board, current_player) do
    Match.new(board, current_player)
  end

  def move(%Match{} = game, notation) do
    with {:ok, game} <- ensure_game_in_progress(game),
         {:ok, move} <- parse_move(game, notation) do
      Match.move(game, move)
    end
  end

  defp ensure_game_in_progress(game) do
    if game.status == :in_progress do
      {:ok, game}
    else
      {:error, :game_over}
    end
  end

  defp parse_move(game, notation) do
    parsed_notation =  AlgebraicNotation.parse(notation)
    moves =
      Move.possible_moves(parsed_notation, game.current_player)
      |> Match.disambiguate_moves(game, game.current_player, parsed_notation)

    possible_moves_count = Enum.count(moves)

    if possible_moves_count == 1 do
      {:ok, Enum.at(moves, 0)}
    else
      {:error, :invalid_move}
    end
  end

  def turn(%Match{} = game, move1, move2) do
    with {:ok, game} <- move(game, move1) do
      move(game, move2)
    end
  end

  def moves(%Match{} = game, moves) when is_list(moves) do
    Enum.reduce_while(moves, {:ok, game}, fn move, {:ok, game} ->
      case move(game, move) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  def turns(%Match{} = game, turns) when is_list(turns) do
    Enum.reduce_while(turns, {:ok, game}, fn turn, {:ok, game} ->
      case moves(game, String.split(turn)) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  def resign(%Match{} = game) do
    Match.resign(game)
  end
end
