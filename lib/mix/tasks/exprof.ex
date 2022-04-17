defmodule Mix.Tasks.Exprof do
  @shortdoc "Profiles Chexx using ExProf"
  use Mix.Task
  import Chexx.AlgebraicNotation, only: [sigil_a: 2]
  import ExProf.Macro

  def run(_args) do
    profile do: play_game_of_the_century()
  end

  defp play_game_of_the_century do
    game = Chexx.start_game()
    {:ok, _game} =
      Chexx.move(game, [
        ~a[Nf3], ~a[Nf6],
        ~a[c4], ~a[g6],
        ~a[Nc3], ~a[Bg7],
        ~a[d4], ~a[0-0],
        ~a[Bf4], ~a[d5],
        ~a[Qb3], ~a[dxc4],
        ~a[Qxc4], ~a[c6],
        ~a[e4], ~a[Nbd7],
        ~a[Rd1], ~a[Nb6],
        ~a[Qc5], ~a[Bg4],
        ~a[Bg5], ~a[Na4],
        ~a[Qa3], ~a[Nxc3],
        ~a[bxc3], ~a[Nxe4],
        ~a[Bxe7], ~a[Qb6],
        ~a[Bc4], ~a[Nxc3],
        ~a[Bc5], ~a[Rfe8+],
        ~a[Kf1], ~a[Be6],
        ~a[Bxb6], ~a[Bxc4+],
        ~a[Kg1], ~a[Ne2+],
        ~a[Kf1], ~a[Nxd4+],
        ~a[Kg1], ~a[Ne2+],
        ~a[Kf1], ~a[Nc3+],
        ~a[Kg1], ~a[axb6],
        ~a[Qb4], ~a[Ra4],
        ~a[Qxb6], ~a[Nxd1],
        ~a[h3], ~a[Rxa2],
        ~a[Kh2], ~a[Nxf2],
        ~a[Re1], ~a[Rxe1],
        ~a[Qd8+], ~a[Bf8],
        ~a[Nxe1], ~a[Bd5],
        ~a[Nf3], ~a[Ne4],
        ~a[Qb8], ~a[b5],
        ~a[h4], ~a[h5],
        ~a[Ne5], ~a[Kg7],
        ~a[Kg1], ~a[Bc5+],
        ~a[Kf1], ~a[Ng3+],
        ~a[Ke1], ~a[Bb4+],
        ~a[Kd1], ~a[Bb3+],
        ~a[Kc1], ~a[Ne2+],
        ~a[Kb1], ~a[Nc3+],
        ~a[Kc1], ~a[Rc2#]
      ])
  end
end
