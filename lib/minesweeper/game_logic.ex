defmodule Minesweeper.GameLogic do
  # {width, height, num_of_mines}
  @difficulty_table %{
    beginner: {10, 10, 10},
    intermediate: {13, 15, 40},
    expert: {30, 16, 99}
  }

  def start_game(params) do
    # Entry point of the front end, should start the Game GenServer that will setup,
    # Should return tuple {status, game_id}
  end

  def setup_board(params) do
  end

  def generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end
end
