defmodule MinesweeperWeb.GameLive.SquareComponent do
  use MinesweeperWeb, :live_component

  alias Minesweeper.SquareServer

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    properties = SquareServer.get({assigns.game_id, assigns.coords}).properties

    socket =
      assign(socket, :game_id, assigns.game_id)
      |> assign(:coords, assigns.coords)
      |> assign(:properties, properties)

    {:ok, socket}
  end

  def show(%{revealed?: false, marked?: false}), do: "empty"

  def show(%{revealed?: false, marked?: true}), do: "flag"

  def show(%{revealed?: true, value: :mine}), do: "mine!"

  def show(%{revealed?: true, value: n}), do: n

  def handle_event("reveal", _from, socket) do
    SquareServer.reveal({socket.assigns.game_id, socket.assigns.coords})

    # send(self(), )
    {:noreply, socket}
  end
end
