defmodule Chexx.Square do
  @type file() :: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  @type file_letter() :: :a | :b | :c | :d | :e | :f | :g | :h
  @type rank() :: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  @type direction() :: :up | :down | :left | :right
  @type distance() :: pos_integer()

  @type t() :: %__MODULE__{
    file: file(),
    rank: rank()
  }

  defguard is_file(file) when file in 1..8
  defguard is_rank(rank) when rank in 1..8

  @enforce_keys [
    :file,
    :rank
  ]
  defstruct [
    :file,
    :rank
  ]

  @spec new(t()) :: t()
  def new(%__MODULE__{} = square) do
    square
  end

  @spec new({file(), rank()}) :: t()
  def new({file, rank}) do
    new(file, rank)
  end

  @spec new(file(), rank()) :: t()
  def new(file, rank) when is_number(file) and is_number(rank) do
    %__MODULE__{file: file, rank: rank}
  end

  @spec new(file_letter(), rank()) :: t()
  def new(file, rank) when is_atom(file) and is_number(rank) do
    new(file_to_number(file), rank)
  end

  def equals?(%__MODULE__{file: square_file, rank: square_rank}, file, rank) do
    square_file == file and square_rank == rank
  end

  def equals?(%__MODULE__{} = a, %__MODULE__{} = b) do
    a.file == b.file and a.rank == b.rank
  end

  @spec to_algebraic(t()) :: String.t()
  def to_algebraic(%__MODULE__{} = square) do
    "#{number_to_file(square.file)}#{square.rank}"
  end

  @spec within?(t(), Range.t(), Range.t()) :: boolean()
  def within?(%__MODULE__{file: source_file, rank: source_rank}, file_range, rank_range) do
    source_rank in rank_range and source_file in file_range
  end

  @spec move_direction(t(), direction(), distance()) :: t()
  def move_direction(%__MODULE__{} = square, direction, distance \\ 1) do
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

  @spec up(t(), distance()) :: t()
  def up(%__MODULE__{file: file, rank: rank}, squares \\ 1) do
    new(file, rank + squares)
  end

  @spec up_right(t(), distance()) :: t()
  def up_right(%__MODULE__{} = start, distance \\ 1) do
    start
    |> up(distance)
    |> right(distance)
  end

  @spec right(t(), distance()) :: t()
  def right(%__MODULE__{file: file, rank: rank}, squares \\ 1) do
    new(file + squares, rank)
  end

  @spec down_right(t(), distance()) :: t()
  def down_right(%__MODULE__{} = start, distance \\ 1) do
    start
    |> down(distance)
    |> right(distance)
  end

  @spec down(t(), distance()) :: t()
  def down(%__MODULE__{file: file, rank: rank}, squares \\ 1) do
    new(file, rank - squares)
  end

  @spec down_left(t(), distance()) :: t()
  def down_left(%__MODULE__{} = start, distance \\ 1) do
    start
    |> down(distance)
    |> left(distance)
  end

  @spec left(t(), distance()) :: t()
  def left(%__MODULE__{file: file, rank: rank}, squares \\ 1) do
    new(file - squares, rank)
  end

  @spec up_left(t(), distance()) :: t()
  def up_left(%__MODULE__{} = start, distance \\ 1) do
    start
    |> up(distance)
    |> left(distance)
  end

  @spec file_to_number(file_letter()) :: file()
  def file_to_number(file)

  def file_to_number(:a), do: 1
  def file_to_number(:b), do: 2
  def file_to_number(:c), do: 3
  def file_to_number(:d), do: 4
  def file_to_number(:e), do: 5
  def file_to_number(:f), do: 6
  def file_to_number(:g), do: 7
  def file_to_number(:h), do: 8

  @spec number_to_file(file()) :: file_letter()
  defp number_to_file(file)

  defp number_to_file(1), do: :a
  defp number_to_file(2), do: :b
  defp number_to_file(3), do: :c
  defp number_to_file(4), do: :d
  defp number_to_file(5), do: :e
  defp number_to_file(6), do: :f
  defp number_to_file(7), do: :g
  defp number_to_file(8), do: :h


  @doc """
  Get the squares in-between two other squares.
  If the squares are not lined up on any axis, then return an empty list.
  """
  @spec squares_between(t(), t()) :: [t()]
  def squares_between(%__MODULE__{file: src_file, rank: src_rank} = src, %__MODULE__{file: dest_file, rank: dest_rank} = dest) do
    cond do
      src_file == dest_file ->
        for rank <- ranks_between(src_rank, dest_rank) do
          new(src_file, rank)
        end
      src_rank == dest_rank ->
        for file <- files_between(src_file, dest_file) do
          new(file, src_rank)
        end
      diagonal_of?(src, dest) ->
        horiz_distance = dest_file - src_file
        vert_distance = dest_rank - src_rank

        for x <- 0..horiz_distance,
            y <- 0..vert_distance,
            x != 0,
            y != 0,
            x != horiz_distance,
            y != vert_distance,
            abs(x) == abs(y) do
          new(src_file + x, src_rank + y)
        end
      true -> []
    end
  end

  @spec diagonal_of?(t(), t()) :: boolean
  defp diagonal_of?(%__MODULE__{file: src_file, rank: src_rank}, %__MODULE__{file: dest_file, rank: dest_rank}) do
    abs(src_file - dest_file) == abs(src_rank - dest_rank)
  end

  @spec ranks_between(rank(), rank()) :: Range.t() | []
  defp ranks_between(src_rank, dest_rank) do
    range_between(src_rank, dest_rank)
  end

  @spec files_between(file(), file()) :: Range.t() | []
  defp files_between(src_file, dest_file) do
    range_between(src_file, dest_file)
  end

  @spec range_between(pos, pos) :: Range.t() | [] when pos: file() | rank()
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

  defimpl Inspect, for: __MODULE__ do
    def inspect(square, _opts) do
      Chexx.Square.to_algebraic(square)
    end
  end
end
