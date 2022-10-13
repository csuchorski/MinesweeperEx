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
    # Increment the count of revealed squares in the GameServer
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :increment_revealed_count)
    # Reveal a square in the SquareServer
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :reveal)
  end

  def mark({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :mark)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:reveal, _from, %{properties: properties} = state) do
    new_state = %{state | properties: %{properties | revealed?: true}}
    {:reply, new_state, new_state}
  end

  def handle_call(:mark, _from, %{properties: %{marked?: true} = properties} = state) do
    new_state = %{state | properties: %{properties | marked?: false}}
    {:reply, new_state, new_state}
  end

  def handle_call(:mark, _from, %{properties: %{marked?: false} = properties} = state) do
    new_state = %{state | properties: %{properties | marked?: true}}
    {:reply, new_state, new_state}
  end
end
