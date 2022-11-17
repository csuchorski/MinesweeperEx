defmodule MinesweeperWeb.GameLive.SquareComponent do
  use MinesweeperWeb, :live_component

  alias Minesweeper.SquareServer

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{game_id: game_id, coords: coords} = assigns, socket) do
    properties = SquareServer.get({game_id, coords}).properties

    socket =
      assign(socket, assigns)
      |> assign(:properties, properties)

    {:ok, socket}
  end

  def update(%{id: _id} = _assigns, socket) do
    properties = SquareServer.get({socket.assigns.game_id, socket.assigns.coords}).properties
    {:ok, assign(socket, :properties, properties)}
  end

  def show(%{revealed?: false, marked?: false}), do: ""

  def show(%{revealed?: false, marked?: true}), do: "flag"

  def show(%{revealed?: true, value: :mine}), do: "mine!"
  def show(%{revealed?: true, value: n}), do: n

  def handle_event("reveal", _from, socket) do
    SquareServer.reveal({socket.assigns.game_id, socket.assigns.coords})

    {:noreply, socket}
  end

  def handle_event("mark", _from, socket) do
    new_props = SquareServer.mark({socket.assigns.game_id, socket.assigns.coords})

    {:noreply, assign(socket, :properties, new_props)}
  end
end
