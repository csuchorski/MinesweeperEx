defmodule MinesweeperWeb.GameLive.Play do
  use MinesweeperWeb, :live_view

  alias Minesweeper.GameServer

  def mount(params, _session, socket) do
    case connected?(socket) do
      false ->
        {:ok, assign(socket, :page, :loading)}

      true ->
        connected_mount(params, socket)
    end
  end

  def connected_mount(params, socket) do
    {:ok, properties} = Minesweeper.GameLogic.start_game(params["diff"])

    Phoenix.PubSub.subscribe(Minesweeper.PubSub, properties.game_id)
    socket = socket |> assign(:page, :loaded) |> assign(properties)
    {:ok, socket}
  end

  def render(%{page: :loading} = assigns) do
    ~H"""
    <p>loading</p>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <p>Game id: <%=@game_id %></p>
      <p>Flag count: <%=@flag_count%>/<%=@mines_count%></p>
      <p>Squares revealed: <%=@squares_revealed_count %></p>
      <p>Time: <%=@time_value %>/<%=@time_limit%></p>
    </div>
    
    <table class ={if @game_status in [:win, :loss], do: "locked"}>
    <%= for row <- 1..@height do  %>
    <tr>
        <%= for col <- 1..@width do%>
            <td>
                <.live_component
                    id={"#{@game_id}-#{col}-#{row}"}
                    module={MinesweeperWeb.GameLive.SquareComponent}
                    game_id={@game_id}
                    coords={{col, row}}
                />
            </td>
        <%end %>
    </tr>
    <%end %>
    </table>
    
    <%= if @game_status == :win do%>
    <p class="game-info">Game won!</p>
    <% end%>
    
    
    <%= if @game_status == :loss do%>
    <p class="game-info">Game lost!</p>
    <% end%>
    
    <button phx-click="return">Return to landing page</button>
    """
  end

  def handle_event("return", _params, %{assigns: %{game_id: game_id}} = socket) do
    GameServer.close_game(game_id)
    {:noreply, redirect(socket, to: "/")}
  end

  def handle_info({:update_square, square_id}, socket) do
    send_update(MinesweeperWeb.GameLive.SquareComponent, id: square_id)

    {:noreply, socket}
  end

  def handle_info(:update_props, socket) do
    new_props = GameServer.get(socket.assigns.game_id)
    squares_revealed = Map.get(new_props, :squares_revealed_count)
    flag_count = Map.get(new_props, :flag_count)
    game_status = Map.get(new_props, :game_status)

    socket =
      socket
      |> assign(:game_status, game_status)
      |> assign(:squares_revealed_count, squares_revealed)
      |> assign(:flag_count, flag_count)

    {:noreply, socket}
  end

  def handle_info(:update_timer, socket) do
    time = GameServer.get_time(socket.assigns.game_id)

    {:noreply, assign(socket, :time_value, time)}
  end

  def handle_info({:change_status, status}, socket),
    do: {:noreply, assign(socket, :game_status, status)}
end
