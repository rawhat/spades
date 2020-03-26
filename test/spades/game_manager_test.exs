defmodule Spades.Game.GameManagerTest do
  use ExUnit.Case

  alias Spades.Game.GameManager

  setup do
    {:ok, pid} = GameManager.start_link()

    p1 = [name: "alex", team: 0]
    p2 = [name: "jon", team: 0]
    p3 = [name: "jake", team: 0]
    p4 = [name: "gopal", team: 0]

    {:ok, pid: pid, p1: p1, p2: p2, p3: p3, p4: p4}
  end

  test "initial state is waiting", %{pid: pid, p1: p1} do
    _ = GameManager.add_player(pid, p1)

    state = GameManager.get_game_state_for_player(pid, p1[:name])

    assert state.state == :waiting
  end

  test "adding players starts game", %{pid: pid, p1: p1, p2: p2, p3: p3, p4: p4} do
    _ = GameManager.add_player(pid, p1)
    _ = GameManager.add_player(pid, p2)
    _ = GameManager.add_player(pid, p3)
    _ = GameManager.add_player(pid, p4)

    state = GameManager.get_game_state_for_player(pid, p1[:name])

    assert state.state == :bidding
  end

  test "making calls begins play", %{pid: pid, p1: p1, p2: p2, p3: p3, p4: p4} do
    _ = GameManager.add_player(pid, p1)
    _ = GameManager.add_player(pid, p2)
    _ = GameManager.add_player(pid, p3)
    _ = GameManager.add_player(pid, p4)

    _ = GameManager.make_call(pid, p1[:name], 1)
    _ = GameManager.make_call(pid, p2[:name], 1)
    _ = GameManager.make_call(pid, p3[:name], 1)
    _ = GameManager.make_call(pid, p4[:name], 1)

    state = GameManager.get_game_state_for_player(pid, p1[:name])

    assert state.state == :playing
  end
end
