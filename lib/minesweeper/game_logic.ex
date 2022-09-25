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

  def setup_board(params) do
    {mine_squares, normal_squares} =
      generate_field(params)
      |> Enum.shuffle()
      |> Enum.split(params.mine_count)

    mine_squares = map_mines_to_squares(mine_squares)
    normal_squares = Enum.into(normal_squares, %{})

    increment_near_bombs(mine_squares, normal_squares)
  end

  @spec generate_id :: binary
  def generate_id() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end

  defp generate_field(params) do
    for x <- 1..params.width, y <- 1..params.height do
      {{x, y}, %{revealed?: false, marked?: false, value: 0}}
    end
  end

  defp map_mines_to_squares(mine_squares) do
    mine_squares
    |> Enum.map(fn {coords, properties} ->
      {coords, %{properties | value: :mine}}
    end)
  end

  defp increment_near_bombs(mine_squares, normal_squares) do
    # Gets coords of all squares touching bombs or bombs themselves
    squares_to_increment =
      for {{bomb_x, bomb_y}, _} <- mine_squares,
          modifier_x <- -1..1,
          modifier_y <- -1..1 do
        if modifier_x == 0 && modifier_y == 0 do
          nil
        else
          {bomb_x + modifier_x, bomb_y + modifier_y}
        end
      end
      |> Enum.reject(fn element -> element == nil end)

    Enum.reduce(squares_to_increment, normal_squares, fn coords, acc ->
      Map.update!(acc, coords, fn properties ->
        %{properties | value: properties.value + 1}
      end)
    end)
  end
end
