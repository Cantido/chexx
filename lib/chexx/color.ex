defmodule Chexx.Color do
  defguard is_color(color) when color == :black or color == :white

  def opponent(:white), do: :black
  def opponent(:black), do: :white
end
