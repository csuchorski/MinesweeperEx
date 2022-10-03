defmodule MinesweeperWeb.GameLive.SquareComponent do
  use MinesweeperWeb, :live_component

  alias Minesweeper.SquareServer

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    properties = SquareServer.get({assigns.game_id, assigns.coords})
    {:ok, assign(socket, Map.merge(assigns, properties))}
  end

  def show(%{revealed?: false, marked?: false}), do: ""

  def show(%{revealed?: false, marked?: true}), do: "flag"

  def show(%{revealed?: true, value: :mine}), do: "mine!"

  def show(%{revealed?: true, value: n}), do: n
end
