defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """
  import Chexx, only: [
    is_color: 1,
    is_piece: 1
  ]

  def new(type, color) when is_piece(type) and is_color(color) do
    %{type: type, color: color}
  end
end
