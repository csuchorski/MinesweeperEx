defmodule Minesweeper.GameServer do
  @moduledoc """
    This module represents a GenServer that handles a minesweeper game instance.
  """
  use GenServer, restart: :temporary

  def start_link(game_params) do
    GenServer.start_link(__MODULE__, game_params,
      name: {:via, Registry, {GameRegistry, game_params.game_id}}
    )
  end

  def init(state) do
    field = Minesweeper.GameLogic.setup_board(state)
    # Minesweeper.GameLogic.setup_timer()
    :erlang.send_after(1000, self(), :tick)

    {:ok, square_supervisor_pid} =
      DynamicSupervisor.start_child(
        MainSquareSupervisor,
        {DynamicSupervisor, strategy: :one_for_one}
      )

    for {coords, properties} <- field do
      DynamicSupervisor.start_child(
        square_supervisor_pid,
        {Minesweeper.SquareServer, {state.game_id, coords, properties}}
      )
    end

    {:ok, %{state | square_supervisor: square_supervisor_pid}}
  end

  def get(game_id) do
    GenServer.call({:via, Registry, {GameRegistry, game_id}}, :get)
  end

  def get_time(game_id) do
    GenServer.call({:via, Registry, {GameRegistry, game_id}}, :get_time)
  end

  def win(game_id) do
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :win)
  end

  def lose(game_id) do
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :loss)
  end

  def close_game(game_id) do
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :close)
  end

  # Handle callbacks

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call(:get_time, _from, %{time_value: time_val} = state),
    do: {:reply, time_val, state}

  def handle_cast(:increment_flags, state) do
    broadcast_game_props_update(state.game_id)

    {:noreply, %{state | flag_count: state.flag_count + 1}}
  end

  def handle_cast(:decrement_flags, state) do
    broadcast_game_props_update(state.game_id)

    {:noreply, %{state | flag_count: state.flag_count - 1}}
  end

  def handle_cast(
        :increment_revealed_count,
        %{
          squares_revealed_count: count,
          revealed_target: target_count
        } = state
      )
      when count + 1 == target_count do
    win(state.game_id)
    {:noreply, %{state | squares_revealed_count: count + 1}}
  end

  def handle_cast(:increment_revealed_count, %{squares_revealed_count: count} = state) do
    broadcast_game_props_update(state.game_id)

    {:noreply, %{state | squares_revealed_count: count + 1}}
  end

  def handle_cast(:close, state), do: {:stop, :shutdown, state}

  def handle_cast(status, state) when status in [:win, :loss] do
    broadcast_game_status(state.game_id, status)
    {:noreply, %{state | game_status: status}}
  end

  def handle_info(
        :tick,
        %{game_id: game_id, time_value: value, time_limit: limit} = state
      ) do
    value = value + 1

    if value <= limit do
      broadcast_time_update(game_id)

      :erlang.send_after(1000, self(), :tick)
      {:noreply, %{state | time_value: value}}
    else
      lose(game_id)
      close_game(game_id)
      {:noreply, %{state | time_value: value}}
      # {:stop, :shutdown, state}
    end
  end

  defp broadcast_game_props_update(game_id) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      game_id,
      :update_props
    )
  end

  defp broadcast_time_update(game_id) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      game_id,
      :update_timer
    )
  end

  defp broadcast_game_status(game_id, status) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      game_id,
      {:change_status, status}
    )
  end
end
