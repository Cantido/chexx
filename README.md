# Chexx

Chexx is a chess library written in Elixir.

It simulates a board with pieces, and will validate moves.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chexx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chexx, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chexx](https://hexdocs.pm/chexx).

## Usage

Start a new game with `Chexx.start_game/0`, and move with `Chexx.move/2`.

    iex> game = Chexx.start_game()
    #Chexx.Match<current_player: :white, status: :in_progress, ...>
    iex> {:ok, game} = Chexx.move(game, "e3")
    ...> game
    #Chexx.Match<current_player: :black, status: :in_progress, ...>
