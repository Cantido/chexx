defmodule Chexx.Square do
  def new({file, rank}) do
    new(file, rank)
  end

  def new(file, rank) when is_number(file) and is_number(rank) do
    {file, rank}
  end

  def new(file, rank) when is_atom(file) and is_number(rank) do
    {file_to_number(file), rank}
  end

  def file({file, _rank}) do
    file
  end

  def rank({_file, rank}) do
    rank
  end

  def coords(square) do
    # normalize using new()
    new(square)
  end

  def to_algebraic(square) do
    {file, rank} = new(square)
    "#{number_to_file(file)}#{rank}"
  end

  def within?({source_file, source_rank}, file_range, rank_range) do
    source_rank in rank_range and source_file in file_range
  end

  def move_direction(square, direction, distance \\ 1) do
    case direction do
      :up -> up(square, distance)
      :up_right -> up_right(square, distance)
      :right -> right(square, distance)
      :down_right -> down_right(square, distance)
      :down -> down(square, distance)
      :down_left -> down_left(square, distance)
      :left -> left(square, distance)
      :up_left -> up_left(square, distance)
    end
  end

  def up({file, rank}, squares \\ 1) do
    {file, rank + squares}
  end

  def up_right(start, distance \\ 1) do
    start
    |> up(distance)
    |> right(distance)
  end

  def right({file, rank}, squares \\ 1) do
    {file + squares, rank}
  end

  def down_right(start, distance \\ 1) do
    start
    |> down(distance)
    |> right(distance)
  end

  def down({file, rank}, squares \\ 1) do
    {file, rank - squares}
  end

  def down_left(start, distance \\ 1) do
    start
    |> down(distance)
    |> left(distance)
  end

  def left({file, rank}, squares \\ 1) do
    {file - squares, rank}
  end

  def up_left(start, distance \\ 1) do
    start
    |> up(distance)
    |> left(distance)
  end

  def file_to_number(:a), do: 1
  def file_to_number(:b), do: 2
  def file_to_number(:c), do: 3
  def file_to_number(:d), do: 4
  def file_to_number(:e), do: 5
  def file_to_number(:f), do: 6
  def file_to_number(:g), do: 7
  def file_to_number(:h), do: 8

  def file_to_number(1), do: 1
  def file_to_number(2), do: 2
  def file_to_number(3), do: 3
  def file_to_number(4), do: 4
  def file_to_number(5), do: 5
  def file_to_number(6), do: 6
  def file_to_number(7), do: 7
  def file_to_number(8), do: 8

  def number_to_file(1), do: :a
  def number_to_file(2), do: :b
  def number_to_file(3), do: :c
  def number_to_file(4), do: :d
  def number_to_file(5), do: :e
  def number_to_file(6), do: :f
  def number_to_file(7), do: :g
  def number_to_file(8), do: :h

  def squares_between({src_file, src_rank}, {dest_file, dest_rank}) do
    cond do
      src_file == dest_file ->
        for rank <- ranks_between(src_rank, dest_rank) do
          {src_file, rank}
        end
      src_rank == dest_rank ->
        for file <- files_between(src_file, dest_file) do
          {file, src_rank}
        end
    end
  end

  defp ranks_between(src_rank, dest_rank) do
    range_between(src_rank, dest_rank)
  end

  defp files_between(src_file, dest_file) do
    range_between(src_file, dest_file)
  end

  defp range_between(first, last) do
    min_val = min(first, last)
    max_val = max(first, last)
    if max_val - min_val == 1 do
      []
    else
      range_start = min_val + 1
      range_end = max_val - 1
      range_start..range_end
    end
  end
end