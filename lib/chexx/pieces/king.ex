defmodule Chexx.Pieces.King do
  alias Chexx.Square
  alias Chexx.Touch
  alias Chexx.Ply
  alias Chexx.Pieces.Rook

  @enforce_keys [:color]
  defstruct [:color]

  def possible_king_moves(%__MODULE__{color: player} = piece, source) do
    normal_moves =
      king_movements(source)
      |> Enum.map(fn destination ->
        Ply.single_touch(piece, source, destination)
      end)

    castle_source =
      case player do
        :white -> Square.new(5, 1)
        :black -> Square.new(5, 8)
      end

    if Square.equals?(source, castle_source) do
      normal_moves ++ kingside_castle(player) ++ queenside_castle(player)
    else
      normal_moves
    end
  end

  def possible_king_sources(piece, destination) do
    king_movements(destination)
    |> Enum.map(fn source ->
      Ply.single_touch(piece, source, destination)
    end)
  end

  defp king_movements(source) do
    for distance <- [1], direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  def kingside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          move.__struct__ == Touch and Enum.any?(move.touches, & &1.piece == %__MODULE__{color: by})
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.touches, fn movement ->
            rook_start_rank =
              case by do
                :white -> 1
                :black -> 8
              end
            move.__struct__ == Touch and
              movement.piece == %Rook{color: by} and
              Square.equals?(movement.source, 8, rook_start_rank)
          end)
        end)

      not king_moved_before? and not rook_moved_before?
    end


    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:g, 1)
        :black -> Square.new(:g, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:h, 1)
        :black -> Square.new(:h, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:f, 1)
        :black -> Square.new(:f, 8)
      end

    vulnerability =
      case by do
        :white -> Square.new(:f, 1)
        :black -> Square.new(:f, 8)
      end

    [%Ply{
      player: by,
      touches: [
        Touch.new(king_start_pos, king_dest_pos, %__MODULE__{color: by}),
        Touch.new(rook_start_pos, rook_dest_pos, %Rook{color: by}),
      ],
      vulnerabilities: [vulnerability],
      match_history_fn: match_history_fn
    }]
  end

  def queenside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          move.__struct__ == Touch and Enum.any?(move.touches, & &1 == %__MODULE__{color: by})
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.touches, fn movement ->
            rook_start_rank =
              case by do
                :white -> 1
                :black -> 8
              end
            move.__struct__ == Touch and movement.piece == %Rook{color: by} and Square.equals?(movement.source, 1, rook_start_rank)
          end)
        end)

      not king_moved_before? and not rook_moved_before?
    end

    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:c, 1)
        :black -> Square.new(:c, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:a, 1)
        :black -> Square.new(:a, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:d, 1)
        :black -> Square.new(:d, 8)
      end

    traversed_square =
      case by do
        :white -> Square.new(:b, 1)
        :black -> Square.new(:b, 8)
      end

    vulnerability =
      case by do
        :white -> Square.new(:d, 1)
        :black -> Square.new(:d, 8)
      end

    [%Ply{
      player: by,
      touches: [
        Touch.new(king_start_pos, king_dest_pos, %__MODULE__{color: by}),
        Touch.new(rook_start_pos, rook_dest_pos, %Rook{color: by}),
      ],
      traverses: [traversed_square],
      vulnerabilities: [vulnerability],
      match_history_fn: match_history_fn
    }]
  end

  defimpl Chexx.Piece do
    def to_string(%{color: :white}), do: "♔"
    def to_string(%{color: :black}), do: "♚"
    def moves_from(piece, square), do: Chexx.Pieces.King.possible_king_moves(piece, square)
    def moves_to(piece, square), do: Chexx.Pieces.King.possible_king_sources(piece, square)
    def type(_piece), do: :king
    def color(%{color: color}), do: color
  end
end
