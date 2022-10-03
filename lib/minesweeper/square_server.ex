defmodule Minesweeper.SquareServer do
  @moduledoc """
    This module represents a GenServer that handles a square in a minesweeper board.
  """
  use GenServer, restart: :temporary

  def start_link({game_id, coords, properties}) do
    GenServer.start_link(__MODULE__, {game_id, {coords, properties}},
      name: {:via, GameRegistry, {game_id, coords}}
    )
  end

  def init({game_id, {coords, properties}}) do
    {:ok, %{game_id: game_id, coords: coords, properties: properties}}
  end

  def get({game_id, {col, row}}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, {col, row}}}}, :get)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
