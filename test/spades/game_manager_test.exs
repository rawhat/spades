defmodule Spades.Game.GameManagerTest do
  use ExUnit.Case

  alias Spades.Game.GameManager
  alias Spades.Game

  setup do
    id = "1"
    id_2 = "2"

    p1 = [id: "0", name: "alex", position: :north]
    p2 = [id: "1", name: "jake", position: :east]
    p3 = [id: "2", name: "jon", position: :south]
    p4 = [id: "3", name: "gopal", position: :west]

    {:ok, _} = GameManager.start_link(id: id, name: "one", game: Game.new(id, "one", p1[:id]))
    {:ok, _} = GameManager.start_link(id: id_2, name: "two", game: Game.new(id_2, "two", p1[:id]))

    {:ok, id: id, p1: p1, p2: p2, p3: p3, p4: p4, id_2: id_2}
  end

  test "initial state is waiting", %{id: id, p1: p1} do
    _ = GameManager.add_player(id, p1)
    state = GameManager.get_game_state_for_player(id, p1[:id])

    assert state.state == :waiting
  end

  test "adding players starts game", %{id: id, p1: p1, p2: p2, p3: p3, p4: p4} do
    _ = GameManager.add_player(id, p1)
    _ = GameManager.add_player(id, p2)
    _ = GameManager.add_player(id, p3)
    _ = GameManager.add_player(id, p4)

    state = GameManager.get_game_state_for_player(id, p1[:name])

    assert state.state == :bidding
  end

  test "making calls begins play", %{id: id, p1: p1, p2: p2, p3: p3, p4: p4} do
    _ = GameManager.add_player(id, p1)
    _ = GameManager.add_player(id, p2)
    _ = GameManager.add_player(id, p3)
    _ = GameManager.add_player(id, p4)

    _ = GameManager.make_call(id, p1[:id], 1)
    _ = GameManager.make_call(id, p2[:id], 1)
    _ = GameManager.make_call(id, p3[:id], 1)
    _ = GameManager.make_call(id, p4[:id], 1)

    state = GameManager.get_game_state_for_player(id, p1[:id])

    assert state.state == :playing
    assert length(state.players) == 4
    assert Enum.find(state.players, &(&1[:id] == p2[:id])).call == 1
  end

  test "it allows multiple games", %{id_2: id, p1: p1} do
    assert GameManager.get_game_state_for_player(id, p1[:id]) == %{
             created_by: p1[:id],
             current_player: :north,
             id: id,
             last_trick: [],
             name: "two",
             players: [],
             player_position: %{},
             scores: %{:north_south => 0, :east_west => 0},
             spades_broken: false,
             state: :waiting,
             trick: []
           }
  end

  test "it returns game state", %{id: id, p1: p1} do
    assert GameManager.get_game_state(id) == %{
             created_by: p1[:id],
             current_player: p1[:position],
             id: "1",
             last_trick: [],
             name: "one",
             players: [],
             player_position: %{},
             scores: %{:north_south => 0, :east_west => 0},
             spades_broken: false,
             state: :waiting,
             trick: []
           }
  end
end
