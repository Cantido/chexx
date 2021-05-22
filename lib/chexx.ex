defmodule Chexx do
  @moduledoc """
  Chexx is a chess library, written in Elixir.
  It simulates a board with pieces, and will validate moves.
  Start a new game with `Chexx.start_game/0`, and move with `Chexx.Ply/2`.

      iex> game = Chexx.start_game()
      #Chexx.Match<current_player: :white, status: :in_progress, ...>
      iex> {:ok, game} = Chexx.move(game, "e3")
      ...> game
      #Chexx.Match<current_player: :black, status: :in_progress, ...>

  You can also start a game with a custom board setup by building a board using the functions in `Chexx.Board`,
  then passing it into `play_board/2` along with the current player.
  Here's an example of building a standard board with no queens, with black moving first.

      iex> board = Chexx.Board.standard()
      ...> board = Chexx.Board.delete_piece(board, 1, 4)
      ...> board = Chexx.Board.delete_piece(board, 8, 4)
      ...> {:ok, game} = Chexx.play_board(board, :black)
      ...> game
      #Chexx.Match<current_player: :black, status: :in_progress, ...>
  """

  alias Chexx.AlgebraicNotation
  alias Chexx.Match
  alias Chexx.Ply

  @doc """
  Start a new game of chess.
  """
  @spec start_game() :: Chexx.Match.t()
  def start_game do
    Match.new()
  end

  @doc """
  Start a new game of chess with a special board and the given player starting.
  """
  @spec play_board(Chexx.Board.t(), Chexx.Color.t()) :: {:ok, Chexx.Match.t()} | {:error, any()}
  def play_board(board, current_player) do
    Match.new(board, current_player)
  end

  @doc """
  Make a move as the current player.
  Provide your move in algebraic notation.
  """
  @spec move(Chexx.Match.t(), String.t()) :: {:ok, Chexx.Match.t()} | {:error, any()}
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
      Ply.possible_moves(parsed_notation, game.current_player)
      |> Match.disambiguate_moves(game, game.current_player, parsed_notation)

    possible_moves_count = Enum.count(moves)

    if possible_moves_count == 1 do
      {:ok, Enum.at(moves, 0)}
    else
      {:error, :invalid_move}
    end
  end

  @doc """
  Make two moves at once.
  This works just as if you called `move/2` twice.
  """
  @spec turn(Chexx.Match.t(), String.t(), String.t()) :: {:ok, Chexx.Match.t()} | {:error, any()}
  def turn(%Match{} = game, move1, move2) do
    with {:ok, game} <- move(game, move1) do
      move(game, move2)
    end
  end

  @doc """
  Make many moves at once.
  This works just as if you called `move/2` multiple times.
  """
  @spec moves(Chexx.Match.t(), [String.t()]) :: {:ok, Chexx.Match.t()} | {:error, any()}
  def moves(%Match{} = game, moves) when is_list(moves) do
    Enum.reduce_while(moves, {:ok, game}, fn move, {:ok, game} ->
      case move(game, move) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  @doc """
  Make many moves at once.
  A turn is two moves separated by a space.
  """
  @spec turns(Chexx.Match.t(), [String.t()]) :: {:ok, Chexx.Match.t()} | {:error, any()}
  def turns(%Match{} = game, turns) when is_list(turns) do
    Enum.reduce_while(turns, {:ok, game}, fn turn, {:ok, game} ->
      case moves(game, String.split(turn)) do
        {:ok, game} -> {:cont, {:ok, game}}
        err -> {:halt, err}
      end
    end)
  end

  @doc """
  Resign the game, as the current player.
  """
  @spec resign(Chexx.Match.t()) :: {:ok, Chexx.Match.t()} | {:error, :game_over}
  def resign(%Match{} = game) do
    Match.resign(game)
  end
end
