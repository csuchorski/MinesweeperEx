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

    {:ok, state, {:continue, :start_game}}
  end

  # Runs right after init of game server, generates the field and starts square servers
  def handle_continue(:start_game, state) do
    field = Minesweeper.GameLogic.setup_board(state)

    for square <- field do
      GenServer.start(Minesweeper.SquareServer, square)
    end
  end

  def handle_call() do
  end

  def handle_cast() do
  end
end
