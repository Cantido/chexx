defmodule Chexx do
  @moduledoc """
  Chexx is a chess library, written in Elixir.
  It simulates a board with pieces, and will validate moves.
  Start a new game with `Chexx.start_game/0`, and play with `Chexx.ply/2`.

      iex> game = Chexx.start_game()
      #Chexx.Game<current_player: :white, status: :in_progress, ...>
      iex> {:ok, game} = Chexx.move(game, ~a[e3])
      ...> game
      #Chexx.Game<current_player: :black, status: :in_progress, ...>

  You can also start a game with a custom board setup by building a board using the functions in `Chexx.Board`,
  then passing it into `play_board/2` along with the current player.
  Here's an example of building a standard board with no queens, with black moving first.

      iex> board = Chexx.Games.Standard.new_board()
      ...> board = Chexx.Board.delete_piece(board, ~q[d1])
      ...> board = Chexx.Board.delete_piece(board, ~q[d8])
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

  You can provide either a single `Chexx.MoveNotation`, or a list of them.
  """
  @spec move(Chexx.Game.t(), Chexx.MoveNotation.t()) :: {:ok, Chexx.Game.t()} | {:error, any()}
  @spec move(Chexx.Game.t(), [Chexx.MoveNotation.t()]) :: {:ok, Chexx.Game.t()} | {:error, any()}

  def move(%Game{} = game, plies) when is_list(plies) do
    Enum.reduce_while(plies, {:ok, game}, fn ply, {:ok, game} ->
      case move(game, ply) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  def move(%Game{} = game, notation) do
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
  This works just as if you called `move/2` twice.
  """
  @spec move(Chexx.Game.t(), Chexx.MoveNotation.t(), Chexx.MoveNotation.t()) :: {:ok, Chexx.Game.t()} | {:error, any()}
  def move(%Game{} = game, ply1, ply2) do
    with {:ok, game} <- move(game, ply1) do
      move(game, ply2)
    end
  end

  @doc """
  Resign the game, as the current player.
  """
  @spec resign(Chexx.Game.t()) :: {:ok, Chexx.Game.t()} | {:error, :game_over}
  def resign(%Game{} = game) do
    Game.resign(game)
  end
end
