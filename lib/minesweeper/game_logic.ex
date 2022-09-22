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

    mine_squares
    |> Enum.map(fn {coords, properties} ->
      {coords, %{properties | value: :mine}}
    end)

    mine_squares ++ normal_squares
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

  defp increment_near_bombs(mine_squares, normal_squares) do
    for bomb_square <- mine_squares,
        {bomb_x, bomb_y} <- bomb_square,
        modifier_x <- -1..1,
        modifier_y <- -1..1,
        coords <- {bomb_x + modifier_x, bomb_y + modifier_y} do
      Enum.reduce(normal_squares, [], fn square, acc ->
        nil
        # {^coords, params} = square
      end)
    end
  end
end

# bomb_x+modifier_x, bomb_y + modifier_y
#  {1,2}
#
# elem(bomb_square , 0)
# for   bomb_square <- mine_squares,
#   {1,2},
