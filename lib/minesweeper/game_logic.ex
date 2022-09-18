defmodule Minesweeper.GameLogic do
  # {width, height, num_of_mines}
  @difficulty_table %{
    beginner: {10, 10, 10},
    intermediate: {13, 15, 40},
    expert: {30, 16, 99}
  }

  def start_game(difficulty) do
    # Entry point of the front end, should start the Game GenServer that will setup,
    # Should return tuple {status, game_id}

    difficulty = String.to_existing_atom(difficulty)
    diff_tuple = Map.fetch!(@difficulty_table, difficulty)

    game_params = %{
      game_id: generate_id(),
      width: diff_tuple |> elem(0),
      height: diff_tuple |> elem(1),
      mines_count: diff_tuple |> elem(2)
    }

    game =
      DynamicSupervisor.start_child(
        Minesweeper.DynamicSupervisor,
        {Minesweeper.GameServer, game_params}
      )

    with {:ok, _pid} <- game do
      {:ok, game_params.game_id}
    else
      {:error, message} -> {:error, message}
    end
  end

  def setup_board(difficulty) do
  end

  @spec generate_id :: binary
  def generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end
end
