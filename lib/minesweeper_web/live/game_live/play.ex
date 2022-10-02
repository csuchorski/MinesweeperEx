defmodule MinesweeperWeb.GameLive.Play do
  use MinesweeperWeb, :live_view

  def mount(params, _session, socket) do
    {:ok, properties} = Minesweeper.GameLogic.start_game(params["diff"])

    {:ok, assign(socket, properties)}
  end
end
