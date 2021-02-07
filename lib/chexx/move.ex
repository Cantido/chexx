defmodule Chexx.Move do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.
  """

  def new(map) when is_map(map) do
    Map.take(map, [
      :movements,
      :capture,
      :captures,
      :captured_piece_type,
      :traverses,
      :match_history_fn
    ])
  end
end
