defmodule Minesweeper.GameServer do
  @moduledoc """
    This module represents a GenServer that handles a minesweeper game instance.
  """
  use GenServer, restart: :temporary

  def init(game_params) do
    state =
      Map.merge(game_params, %{
        square_supervisor: nil,
        flag_count: 0,
        squares_revealed_count: 0
      })

    field = Minesweeper.GameLogic.setup_board(state)

    {:ok, square_supervisor_pid} =
      DynamicSupervisor.start_child(
        Minesweeper.DynamicSupervisor,
        {DynamicSupervisor, strategy: :one_for_one}
      )

    for {coords, properties} <- field do
      DynamicSupervisor.start_child(
        square_supervisor_pid,
        {Minesweeper.SquareServer, {state.game_id, {coords, properties}}}
      )
    end

    {:ok, %{state | square_supervisor: square_supervisor_pid}}
  end

  def handle_call() do
  end

  def handle_cast() do
  end
end
