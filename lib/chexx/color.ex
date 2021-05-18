defmodule Chexx.Color do
  @moduledoc """
  A player's piece color: either white or black.
  """

  @type t() :: :white | :black

  defguard is_color(color) when color == :black or color == :white

  @doc """
  Get the opponent of the given color.
  """
  @spec opponent(:white) :: :black
  @spec opponent(:black) :: :white
  def opponent(:white), do: :black
  def opponent(:black), do: :white
end
