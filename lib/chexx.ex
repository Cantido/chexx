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

  def move(game, notation) do
    try do
      {:ok, do_move(game, notation)}
    rescue
       e in RuntimeError ->
         {:error, {:invalid_move, e}}
    end
  end

  defp do_move(game, notation) do
    unless game.status == :in_progress do
      raise "Game ended, status: #{game.status}"
    end

    parsed_notation =  AlgebraicNotation.parse(notation)
    moves =
      Move.possible_moves(parsed_notation, game.current_player)
      |> Match.disambiguate_moves(game, game.current_player, parsed_notation)

    if Enum.empty?(moves) do
      raise "No valid moves found for #{game.current_player} matching #{inspect notation}. on this board: \n#{inspect(game.board)}\n"
    end

    possible_moves_count = Enum.count(moves)
    if possible_moves_count > 1 do
      raise "Ambiguous move: notation #{notation} can mean #{possible_moves_count} possible moves: #{inspect moves}"
    end

    move = Enum.at(moves, 0)

    Match.move(game, move)
  end

  def turn(game, move1, move2) do
    with {:ok, game} <- move(game, move1) do
      move(game, move2)
    end
  end

  def moves(game, moves) when is_list(moves) do
    Enum.reduce_while(moves, {:ok, game}, fn move, {:ok, game} ->
      case move(game, move) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  def turns(game, turns) when is_list(turns) do
    Enum.reduce_while(turns, {:ok, game}, fn turn, {:ok, game} ->
      case moves(game, String.split(turn)) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  def resign(game) do
    {:ok, Match.resign(game)}
  end
end
