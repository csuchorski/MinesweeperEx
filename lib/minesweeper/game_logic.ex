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
      mines_count: diff_tuple |> elem(2),
      revealed_target: elem(diff_tuple, 0) * elem(diff_tuple, 1) - elem(diff_tuple, 2),
      square_supervisor: nil,
      flag_count: 0,
      squares_revealed_count: 0,
      time_limit: 300,
      time_value: 0,
      timer_pid: nil,
      game_status: :pending
    }

    game =
      DynamicSupervisor.start_child(
        GameSupervisor,
        {Minesweeper.GameServer, game_params}
      )

    with {:ok, _pid} <- game do
      {:ok, game_params}
    else
      {:error, message} -> {:error, message}
    end
  end

  def setup_board(params) do
    {mine_squares, normal_squares} =
      generate_field(params)
      |> Enum.shuffle()
      |> Enum.split(params.mines_count)

    mine_squares = map_mines_to_squares(mine_squares)
    normal_squares = Enum.into(normal_squares, %{})

    increment_near_bombs(mine_squares, normal_squares)
  end

  def setup_timer() do
    :erlang.send_after(1000, self(), :tick)
  end

  @spec generate_id :: binary
  def generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end

  def generate_field(params) do
    for x <- 1..params.width, y <- 1..params.height do
      {{x, y}, %{revealed?: false, marked?: false, value: 0}}
    end
  end

  defp map_mines_to_squares(mine_squares) do
    mine_squares
    |> Enum.map(fn {coords, properties} ->
      {coords, %{properties | value: :mine}}
    end)
    |> Enum.into(%{})
  end

  defp increment_near_bombs(mine_squares, normal_squares) do
    bomb_coords = Map.keys(mine_squares)
    full_field = Map.merge(mine_squares, normal_squares)

    Enum.reduce(bomb_coords, full_field, fn {bomb_x, bomb_y}, full_field ->
      for mod_x <- -1..1,
          mod_y <- -1..1,
          square_coords = {bomb_x + mod_x, bomb_y + mod_y},
          is_map_key(full_field, square_coords),
          Map.get(full_field, square_coords).value != :mine,
          reduce: full_field do
        full_field ->
          Map.update!(full_field, square_coords, fn square_properties ->
            %{square_properties | value: square_properties.value + 1}
          end)
      end
    end)
  end
end
