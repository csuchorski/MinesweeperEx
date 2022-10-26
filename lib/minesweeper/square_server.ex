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

  # Custom functions

  def get({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :get)
  end

  def reveal({game_id, coords}) do
    # Reveal a square in the SquareServer
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :reveal)
  end

  def chain_reveal(game_id, {x, y}) do
    neighbouring_zero_squares =
      for mod_x <- -1..1,
          mod_y <- -1..1,
          square_coords = {x + mod_x, y + mod_y},
          square_coords != {x, y},
          !Enum.empty?(Registry.lookup(GameRegistry, {game_id, square_coords})),
          get({game_id, square_coords}).properties.value == 0 do
        {game_id, square_coords}
      end

    Enum.each(neighbouring_zero_squares, fn tuple ->
      reveal(tuple)
    end)
  end

  def mark({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :mark)
  end

  # Handle callbacks

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call(:reveal, _from, %{properties: properties} = state) do
    GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :increment_revealed_count)

    if properties.marked? == true do
      GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :decrement_flags)
    end

    if properties.value == 0 do
      chain_reveal(state.game_id, state.coords)
    end

    new_state = %{state | properties: %{properties | revealed?: true, marked?: false}}
    {:reply, new_state.properties, new_state}
  end

  def handle_call(:mark, _from, %{properties: %{revealed?: true}} = state) do
    {:reply, state.properties, state}
  end

  def handle_call(:mark, _from, %{properties: %{marked?: true} = properties} = state) do
    GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :decrement_flags)

    new_state = %{state | properties: %{properties | marked?: false}}
    {:reply, new_state.properties, new_state}
  end

  def handle_call(:mark, _from, %{properties: %{marked?: false} = properties} = state) do
    GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :increment_flags)

    new_state = %{state | properties: %{properties | marked?: true}}
    {:reply, new_state.properties, new_state}
  end
end
