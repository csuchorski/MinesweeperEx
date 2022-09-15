defmodule Minesweeper.SquareServer do
  @moduledoc """
    This module represents a GenServer that handles a square in a minesweeper board.
  """
  use GenServer, restart: :temporary
end
