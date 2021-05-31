defmodule Chexx.PGN.Parser do
  use AbnfParsec,
    abnf_file: "priv/pgn.abnf",
    parse: :pgndatabase,
    transform: %{
      "latin1char" => {:reduce, {List, :to_string, []}},
      "moves" => {:reduce, {Chexx.PGN.Parser, :reduce_moves, []}},
      "tags" => [{:map, {Chexx.PGN.Parser, :collapse_tag, []}}, {:reduce, {Map, :new, []}}],
      "taglabel" => {:reduce, {List, :to_string, []}},
      "string" => {:reduce, {Enum, :join, []}},
      "san" => {:reduce, {List, :to_string, []}},
      "movenumber" => [{:reduce, {List, :to_string, []}}, {:map, {String, :to_integer, []}}],
      "comment" => {:reduce, {Enum, :join, []}}
    },
    unwrap: [
      "movenumber",
      "taglabel",
      "tagvalue",
      "termination",
      "san"
    ],
    unbox: [
      "latin1char",
      "string",
      "element"
      ],
    untag: [
      "tag"
    ],
    ignore: [
      "dot",
      "newline",
      "separator",
      "begintag",
      "endtag",
      "tagseparator",
      "beginstring",
      "endstring"
    ]

  @external_resource "priv/pgn.abnf"

  def collapse_tag([taglabel: label, tagvalue: value]) do
    {label, value}
  end

  def reduce_moves(elements) do
    # Build the move list backwards, then reverse it at the end
    Enum.reduce(elements, [], fn {type, value}, moves ->
      case type do
        :movenumber -> [%{move_number: value} | moves]
        :san ->
          List.update_at(moves, 0, fn move ->
            if Map.has_key?(move, :white_move) do
              Map.put(move, :black_move, value)
            else
              Map.put(move, :white_move, value)
            end
          end)
      end
    end)
  end
end
