defmodule Chexx do
  @moduledoc """
  Chexx is a chess library, written in Elixir.
  It simulates a board with pieces, and will validate moves.
  Start a new game with `Chexx.start_game/0`, and play with `Chexx.ply/2`.

      iex> game = Chexx.start_game()
      #Chexx.Game<current_player: :white, status: :in_progress, ...>
      iex> {:ok, game} = Chexx.ply(game, "e3")
      ...> game
      #Chexx.Game<current_player: :black, status: :in_progress, ...>

  You can also start a game with a custom board setup by building a board using the functions in `Chexx.Board`,
  then passing it into `play_board/2` along with the current player.
  Here's an example of building a standard board with no queens, with black moving first.

      iex> board = Chexx.Games.Standard.new_board()
      ...> board = Chexx.Board.delete_piece(board, 1, 4)
      ...> board = Chexx.Board.delete_piece(board, 8, 4)
      ...> {:ok, game} = Chexx.play_board(board, :black)
      ...> game
      #Chexx.Game<current_player: :black, status: :in_progress, ...>
  """

  alias Chexx.Game

  @doc """
  Start a new game of chess.
  """
  @spec start_game() :: Chexx.Game.t()
  def start_game do
    Game.new()
  end

  @doc """
  Start a new game of chess with a special board and the given player starting.
  """
  @spec play_board(Chexx.Board.t(), Chexx.Color.t()) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def play_board(board, current_player) do
    Game.new(board, current_player)
  end

  @doc """
  Make a move as the current player.
  Provide your move in algebraic notation.
  """
  @spec ply(Chexx.Game.t(), String.t()) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def ply(%Game{} = game, notation) do
    with {:ok, game} <- ensure_game_in_progress(game) do
      Game.move(game, notation)
    end
  end

  defp ensure_game_in_progress(game) do
    if game.status == :in_progress do
      {:ok, game}
    else
      {:error, :game_over}
    end
  end

  @doc """
  Make two plies at once.
  This works just as if you called `ply/2` twice.
  """
  @spec move(Chexx.Game.t(), String.t(), String.t()) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def move(%Game{} = game, ply1, ply2) do
    with {:ok, game} <- ply(game, ply1) do
      ply(game, ply2)
    end
  end

  @doc """
  Make many plies at once.
  This works just as if you called `ply/2` multiple times.
  """
  @spec plies(Chexx.Game.t(), [String.t()]) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def plies(%Game{} = game, plies) when is_list(plies) do
    Enum.reduce_while(plies, {:ok, game}, fn ply, {:ok, game} ->
      case ply(game, ply) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  @doc """
  Make many moves at once.
  A moves is two plies separated by a space.
  """
  @spec moves(Chexx.Game.t(), [String.t()]) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def moves(%Game{} = game, turns) when is_list(turns) do
    Enum.reduce_while(turns, {:ok, game}, fn turn, {:ok, game} ->
      case plies(game, String.split(turn)) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  @doc """
  Resign the game, as the current player.
  """
  @spec resign(Chexx.Game.t()) :: {:ok, Chexx.Game.t()} | {:error, :game_over}
  def resign(%Game{} = game) do
    Game.resign(game)
  end
end
