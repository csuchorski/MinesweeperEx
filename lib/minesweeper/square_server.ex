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
    GenServer.cast({:via, Registry, {GameRegistry, {game_id, coords}}}, :reveal)
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
      Process.sleep(100)
      reveal(tuple)
    end)
  end

  def mark({game_id, coords}) do
    GenServer.call({:via, Registry, {GameRegistry, {game_id, coords}}}, :mark)
  end

  # Handle callbacks

  # Get state
  def handle_call(:get, _from, state), do: {:reply, state, state}

  # Flags
  def handle_call(:mark, _from, %{properties: %{revealed?: true}} = state),
    do: {:reply, state.properties, state}

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

  # Reveals
  def handle_cast(:reveal, %{game_id: game_id, properties: %{value: :mine} = properties} = state) do
    broadcast_square_update(state)
    # Minesweeper.GameServer.lose(game_id)
    {:noreply, %{state | properties: %{properties | revealed?: true}}}
  end

  def handle_cast(:reveal, %{properties: %{revealed?: true}} = state),
    do: {:noreply, state}

  def handle_cast(:reveal, %{properties: properties} = state) do
    GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :increment_revealed_count)

    if properties.marked? == true do
      GenServer.cast({:via, Registry, {GameRegistry, state.game_id}}, :decrement_flags)
    end

    new_state = %{state | properties: %{properties | revealed?: true, marked?: false}}

    broadcast_square_update(state)

    if properties.value == 0 do
      Task.start(Minesweeper.SquareServer, :chain_reveal, [new_state.game_id, new_state.coords])
      {:noreply, new_state}
    else
      {:noreply, new_state}
    end
  end

  def handle_continue(:chain_reveal, %{game_id: game_id, coords: coords} = state) do
    chain_reveal(game_id, coords)
    {:noreply, state}
  end

  # PubSub broadcast
  defp broadcast_square_update(%{game_id: game_id, coords: {x, y}} = state) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      state.game_id,
      {:update_square, "#{game_id}-#{x}-#{y}"}
    )
  end
end
