defmodule MinesweeperWeb.GameLive.Play do
  use MinesweeperWeb, :live_view

  alias Minesweeper.GameServer

  def mount(params, _session, socket) do
    {:ok, properties} = Minesweeper.GameLogic.start_game(params["diff"])

    Phoenix.PubSub.subscribe(Minesweeper.PubSub, properties.game_id)

    {:ok, assign(socket, properties)}
  end

  def handle_info({:update_square, square_id}, socket) do
    send_update(MinesweeperWeb.GameLive.SquareComponent, id: square_id)

    {:noreply, socket}
  end

  def handle_info(:update_props, socket) do
    new_props = GameServer.get(socket.assigns.game_id)
    squares_revealed = Map.get(new_props, :squares_revealed_count)
    flag_count = Map.get(new_props, :flag_count)

    socket =
      socket
      |> assign(:squares_revealed_count, squares_revealed)
      |> assign(:flag_count, flag_count)

    {:noreply, socket}
  end
end
