defmodule Chexx.AlgebraicNotation do

  alias Chexx.Square

  @notation_regex ~r/^(?<moved_piece>[KQRBNp]?)(?<source_file>[a-h]?)(?<source_rank>[1-8]?)(?<capture_flag>x?)(?<dest_file>[a-h])(?<dest_rank>[1-8])(?<promotion_piece>[QRBN])?(?<check_flag>\+)?(?<checkmate_flag>#)?$/

  def parse(notation) do
    case notation do
      # TODO: allow castling to mark the check? flag
      "0-0" -> %{move_type: :kingside_castle, check?: false, notation_source: "0-0"}
      "0-0-0" -> %{move_type: :queenside_castle, check?: false, notation_source: "0-0-0"}
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
        |> Square.file_to_number()
      end

    source_rank_notation = Map.get(captures, "source_rank")
    source_rank =
      if source_rank_notation == "" do
        nil
      else
        {source_rank, ""} = Integer.parse(source_rank_notation)
        source_rank
      end

    capture_type =
      if Map.get(captures, "capture_flag") == "x" do
        :required
      else
        :forbidden
      end

    check =
      cond do
        Map.get(captures, "checkmate_flag") == "#" -> :checkmate
        Map.get(captures, "check_flag") == "+" -> :check
        true -> :none
      end

    promoted_to =
      case Map.get(captures, "promotion_piece") do
        "Q" -> :queen
        "B" -> :bishop
        "N" -> :knight
        "R" -> :rook
        "" -> nil
      end

    %{
      move_type: :regular,
      piece_type: moved_piece,
      source_file: source_file,
      source_rank: source_rank,
      destination: Square.new(dest_file, dest_rank),
      capture: capture_type,
      check_status: check,
      promoted_to: promoted_to,
      notation_source: notation
    }
  end
end
