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
        squares_revealed_count: 0,
        mine_positions: nil
      })

    {:ok, state, {:continue, :start_game}}
  end

  def handle_call() do
  end

  def handle_cast() do
  end
end
