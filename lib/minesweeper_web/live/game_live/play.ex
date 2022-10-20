defmodule MinesweeperWeb.GameLive.Play do
  use MinesweeperWeb, :live_view

  alias Minesweeper.GameServer

  def mount(params, _session, socket) do
    {:ok, properties} = Minesweeper.GameLogic.start_game(params["diff"])

    {:ok, assign(socket, properties)}
  end

  def handle_event("update_flag_count", _params, socket) do
    new_flag_count = GameServer.get(socket.assigns.game_id) |> Map.get(:flag_count)

    {:noreply, assign(socket, :flag_count, new_flag_count)}
  end
end
