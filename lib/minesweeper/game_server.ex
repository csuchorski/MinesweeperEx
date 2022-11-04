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

  def win(game_id) do
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :win)
  end

  def lose(game_id) do
    GenServer.cast({:via, Registry, {GameRegistry, game_id}}, :loss)
  end

  # Handle callbacks

  def handle_call(:get, _From, state), do: {:reply, state, state}

  def handle_cast(:increment_flags, state) do
    broadcast_game_props_update(state)

    {:noreply, %{state | flag_count: state.flag_count + 1}}
  end

  def handle_cast(:decrement_flags, state) do
    broadcast_game_props_update(state)

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
    broadcast_game_props_update(state)

    {:noreply, %{state | squares_revealed_count: count + 1}}
  end

  def handle_cast(status, state) when status in [:win, :loss] do
    broadcast_game_props_update(state)
    # broadcast_game_status_change(state, status)
    {:noreply, %{state | game_status: status}}
  end

  defp broadcast_game_props_update(state) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      state.game_id,
      :update_props
    )
  end

  defp broadcast_game_status_change(%{game_id: game_id}, status) do
    Phoenix.PubSub.broadcast(
      Minesweeper.PubSub,
      game_id,
      {:change_status, status}
    )
  end
end
