defmodule MinesweeperWeb.GameLive.Play do
  use MinesweeperWeb, :live_view

  def mount(params, _session, socket) do
    {:ok, assign(socket, :diff, params["diff"])}
  end
end
