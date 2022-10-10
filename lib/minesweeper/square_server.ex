defmodule Minesweeper.SquareServer do
  @moduledoc """
    This module represents a GenServer that handles a square in a minesweeper board.
  """
  use GenServer, restart: :temporary

  def start_link({game_id, coords, properties}) do
    GenServer.start_link(__MODULE__, {game_id, {coords, properties}},
      name: {:via, Registry, {GameRegistry, {game_id, coords}}}
    )
  end

  def init({game_id, {coords, properties}}) do
    {:ok, %{game_id: game_id, coords: coords, properties: properties}}
  end

  def get({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :get)
  end

  def reveal({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :reveal)
  end

  def mark({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :mark)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:reveal, _from, state) do
    {:reply, %{state | revealed?: true}}
  end

  def handle_call(:mark, _from, %{marked?: true} = state) do
    {:reply, %{state | marked?: false}, %{state | marked?: false}}
  end

  def handle_call(:mark, _from, %{marked?: false} = state) do
    {:reply, %{state | marked?: true}, %{state | marked?: true}}
  end
end
