defmodule Chexx.Move do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.

  A Move is usually built from a single `Chexx.Touch`, but some moves require multiple touches,
  like castling.
  """

  alias Chexx.Touch
  alias Chexx.Square

  @enforce_keys [
    :movements
  ]
  defstruct [
    movements: nil,
    capture: nil,
    captures: nil,
    captured_piece_type: nil,
    traverses: [],
    match_history_fn: &__MODULE__.default_match_history_fn/1
  ]

  def new(map) when is_map(map) do
    params = Map.take(map, [
      :movements,
      :capture,
      :captures,
      :captured_piece_type,
      :traverses,
      :match_history_fn
    ])
    struct(__MODULE__, params)
  end

  def default_match_history_fn(_), do: true

  def single_touch(piece, source, destination, opts \\ []) do
    traverses =
      if Keyword.get(opts, :traverses, true) do
        Square.squares_between(source, destination)
      else
        []
      end

    capture = Keyword.get(opts, :capture, :allowed)

    %__MODULE__{
      movements: [Touch.new(source, destination, piece)],
      capture: capture,
      captures: destination,
      traverses: traverses
    }
  end
end
