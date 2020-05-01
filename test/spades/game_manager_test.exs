defmodule Spades.Game.GameManagerTest do
  use ExUnit.Case

  alias Spades.Game.GameManager

  setup do
    id = "1"
    id_2 = "2"
    {:ok, _} = GameManager.start_link(id: id, name: "one")
    {:ok, _} = GameManager.start_link(id: id_2, name: "two")

    p1 = [name: "alex", team: 0]
    p2 = [name: "jake", team: 1]
    p3 = [name: "jon", team: 0]
    p4 = [name: "gopal", team: 1]

    {:ok, id: id, p1: p1, p2: p2, p3: p3, p4: p4, id_2: id_2}
  end

  test "initial state is waiting", %{id: id, p1: p1} do
    _ = GameManager.add_player(id, p1)

    state = GameManager.get_game_state_for_player(id, p1[:name])

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

    _ = GameManager.make_call(id, p1[:name], 1)
    _ = GameManager.make_call(id, p2[:name], 1)
    _ = GameManager.make_call(id, p3[:name], 1)
    _ = GameManager.make_call(id, p4[:name], 1)

    state = GameManager.get_game_state_for_player(id, p1[:name])

    assert state.state == :playing
    assert length(state.players) == 4
    assert Enum.find(state.players, &(&1[:name] == p2[:name])).call == 1
  end

  test "it allows multiple games", %{id_2: id_2, p1: p1} do
    assert GameManager.get_game_state_for_player(id_2, p1[:name]) == %{
             current_player: 0,
             id: "2",
             name: "two",
             players: [],
             scores: %{0 => 0, 1 => 0},
             spades_broken: false,
             state: :waiting,
             trick: []
           }
  end

  test "it returns game state", %{id: id} do
    assert GameManager.get_game_state(id) == %{
             current_player: 0,
             id: "1",
             name: "one",
             players: [],
             scores: %{0 => 0, 1 => 0},
             spades_broken: false,
             state: :waiting,
             trick: []
           }
  end
end
