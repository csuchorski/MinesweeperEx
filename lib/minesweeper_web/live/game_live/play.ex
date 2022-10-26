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

  def handle_event("update_revealed_count", _params, socket) do
    new_revealed_count =
      GameServer.get(socket.assigns.game_id) |> Map.get(:squares_revealed_count)

    {:noreply, assign(socket, :squares_revealed_count, new_revealed_count)}
  end
end
