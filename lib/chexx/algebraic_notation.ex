defmodule Chexx.AlgebraicNotation do

  alias Chexx.Square

  @notation_regex ~r/^(?<moved_piece>[KQRBNp]?)(?<source_file>[a-h]?)(?<source_rank>[1-8]?)(?<capture_flag>x?)(?<dest_file>[a-h])(?<dest_rank>[1-8])(?<check_flag>\+)?$/

  def parse(notation) do
    case notation do
      # TODO: allow castling to mark the check? flag
      "0-0" -> %{move_type: :kingside_castle, check?: false}
      "0-0-0" -> %{move_type: :queenside_castle, check?: false}
      notation -> parse_regular_coords(notation)
    end
  end

  defp parse_regular_coords(notation) do
    unless String.match?(notation, @notation_regex) do
      raise "Notation #{inspect notation} not recognized"
    end

    captures = Regex.named_captures(@notation_regex, notation)

    moved_piece =
      case Map.get(captures, "moved_piece") do
        "K" -> :king
        "Q" -> :queen
        "R" -> :rook
        "B" -> :bishop
        "N" -> :knight
        "p" -> :pawn
        "" -> :pawn
      end

    dest_file = captures["dest_file"] |> String.to_existing_atom()
    {dest_rank, ""} = captures["dest_rank"] |> Integer.parse()

    source_file_notation = Map.get(captures, "source_file")
    source_file =
      if source_file_notation == "" do
        nil
      else
        String.to_existing_atom(source_file_notation)
      end

    source_rank_notation = Map.get(captures, "source_rank")
    source_rank =
      if source_rank_notation == "" do
        nil
      else
        String.to_existing_atom(source_rank_notation)
      end

    source =
      cond do
        not is_nil(source_file) and not is_nil(source_rank) -> Square.new(source_file, source_rank)
        not is_nil(source_file) -> source_file
        true -> nil
      end

    capture_type =
      if Map.get(captures, "capture_flag") == "x" do
        :required
      else
        :forbidden
      end

    %{
      move_type: :regular,
      piece_type: moved_piece,
      source: source,
      destination: Square.new(dest_file, dest_rank),
      capture: capture_type,
      check?: Map.get(captures, "check_flag") == "+"
    }
  end
end
