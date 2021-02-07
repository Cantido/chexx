defmodule Chexx.Move do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.
  """

  @enforce_keys [
    :player,
    :movements
  ]
  defstruct [
    player: nil,
    movements: nil,
    capture: nil,
    captures: nil,
    captured_piece_type: nil,
    traverses: [],
    match_history_fn: &__MODULE__.default_match_history_fn/1
  ]

  def new(map) when is_map(map) do
    params = Map.take(map, [
      :player,
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
end
