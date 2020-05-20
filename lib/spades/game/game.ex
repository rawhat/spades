defmodule Spades.Game do
  defstruct ~w(advance current_player deck id name play_order players scores spades_broken state trick)a

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Player

  def new(id, name, deck \\ Deck.new()) when is_binary(id) do
    %__MODULE__{
      current_player: 0,
      deck: deck,
      id: id,
      name: name,
      players: %{},
      play_order: [],
      scores: %{:north_south => 0, :east_west => 0},
      spades_broken: false,
      state: :waiting,
      trick: []
    }
  end

  def add_player(
        %__MODULE__{} = game,
        %Player{} = player
      ) do
    game
    |> maybe_put_player(player)
    |> maybe_deal_cards()
    |> maybe_start_bidding()
  end

  def state_for_player(%__MODULE__{} = game, id) do
    player = Map.get(game.players, id)

    if player == nil do
      state(game)
    else
      revealed = player.hand != nil && player.hand.revealed

      %{
        id: game.id,
        cards: Player.sorted_hand(player),
        call: if(player.hand != nil, do: player.hand.call, else: nil),
        current_player: game.current_player,
        name: game.name,
        tricks: if(player.hand != nil, do: player.hand.tricks, else: nil),
        team: player.team,
        scores: game.scores,
        players: get_player_list(game),
        spades_broken: game.spades_broken,
        state: game.state,
        trick: game.trick,
        revealed: revealed
      }
    end
  end

  def state(%__MODULE__{} = game) do
    %{
      id: game.id,
      current_player: game.current_player,
      scores: game.scores,
      name: game.name,
      players: get_player_list(game),
      spades_broken: game.spades_broken,
      state: game.state,
      trick: game.trick
    }
  end

  defp get_player_list(game) do
    Stream.map(game.play_order, &Map.get(game.players, &1))
    |> Stream.map(&Player.to_public/1)
    |> Enum.to_list()
  end

  def reveal_cards(
        %__MODULE__{state: :bidding} = game,
        name
      ) do
    if can_play?(game, name) do
      reveal_player_card(game, name)
    else
      game
    end
  end

  def reveal_cards(game, _name), do: game

  def make_call(
        %__MODULE__{state: :bidding} = game,
        id,
        call
      ) do
    if can_play?(game, id) do
      game
      |> maybe_make_call(id, call)
      |> next_player()
      |> maybe_start_game()
    else
      game
    end
  end

  def make_call(game, _name, _call), do: game

  def play_card(
        %__MODULE__{state: :playing} = game,
        id,
        %Card{} = card
      ) do
    if can_play?(game, id) do
      game
      |> maybe_play_card(id, card)
      |> next_player()
      |> maybe_award_trick()
      |> maybe_end_hand()
      |> maybe_end_round()
    else
      game
    end
  end

  def play_card(game, _name, _card), do: game

  defp maybe_put_player(%__MODULE__{players: players} = game, player) do
    if map_size(players) == 4 || Map.has_key?(players, player.id) ||
         Enum.count(players, fn {_, p} -> p.team == player.team end) == 2 do
      game
    else
      new_players = Map.put(players, player.id, player)

      play_order =
        Enum.concat(game.play_order, [player.id])
        |> Enum.split_with(&(Map.get(new_players, &1).team == :north_south))
        |> Tuple.to_list()
        |> zip()

      %{
        game
        | players: new_players,
          play_order: play_order
      }
    end
  end

  defp advance(game) do
    %{game | advance: true}
  end

  defp maybe_deal_cards(%__MODULE__{players: players} = game) when map_size(players) == 4 do
    deal_cards(game)
  end

  defp maybe_deal_cards(game), do: game

  defp maybe_start_bidding(%__MODULE__{players: players, state: :waiting} = game)
       when map_size(players) == 4 do
    %{game | state: :bidding}
  end

  defp maybe_start_bidding(game), do: game

  defp can_play?(game, id) do
    Enum.at(game.play_order, game.current_player) == id
  end

  defp next_player(%__MODULE__{advance: true} = game) do
    # TODO
    %{game | current_player: rem(game.current_player + 1, 4), advance: false}
  end

  defp next_player(game), do: game

  def maybe_make_call(
        %__MODULE__{} = game,
        id,
        call
      ) do
    if can_play?(game, id) do
      %{game | players: Map.update!(game.players, id, &Player.make_call(&1, call))}
      |> advance()
    else
      game
    end
  end

  defp maybe_play_card(%__MODULE__{trick: [], players: players} = game, id, card) do
    if Player.can_play?(players[id], card, nil, game.spades_broken) do
      %{game | trick: [%{id: id, card: card}]}
      |> take_card_from_hand(id, card)
      |> spades_broken(card)
      |> advance()
    else
      game
    end
  end

  defp maybe_play_card(
         %__MODULE__{trick: [%{card: lead} | _] = trick, players: players} = game,
         id,
         card
       ) do
    if Player.can_play?(players[id], card, lead, game.spades_broken) do
      %{game | trick: Enum.concat(trick, [%{id: id, card: card}])}
      |> take_card_from_hand(id, card)
      |> spades_broken(card)
      |> advance()
    else
      game
    end
  end

  defp spades_broken(game, card) do
    %{game | spades_broken: card.suit == :spades || game.spades_broken}
  end

  defp take_card_from_hand(game, id, card) do
    %{game | players: Map.update!(game.players, id, &Player.play_card(&1, card))}
  end

  defp maybe_award_trick(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    [%{card: lead} | _] = trick

    max_spade = Card.max_spade(trick)

    id =
      cond do
        lead.suit == :spade || max_spade != nil ->
          Map.get(max_spade, :id)

        true ->
          Card.max_of_suit(trick, lead.suit)
          |> Map.get(:id)
      end

    winner = Enum.find_index(game.play_order, &(&1 == id))

    %{
      game
      | players: Map.update!(game.players, id, &Player.take(&1)),
        current_player: winner
    }
  end

  defp maybe_award_trick(game), do: next_player(game)

  defp maybe_start_game(game) do
    if Enum.all?(game.players, &(elem(&1, 1).hand.call != nil)) do
      %{game | state: :playing}
    else
      game
    end
  end

  defp maybe_end_hand(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    %{game | trick: []}
  end

  defp maybe_end_hand(game), do: game

  defp maybe_end_round(%__MODULE__{players: players} = game) do
    all_empty =
      Enum.all?(players, fn {_, player} ->
        Enum.empty?(player.hand.cards)
      end)

    if all_empty do
      game
      |> award_points()
      |> increment_play_order()
      |> deal_cards(true)
      |> start_bidding()
    else
      game
    end
  end

  defp reveal_player_card(game, id) do
    player = Map.get(game.players, id)

    if player == nil do
      game
    else
      %{game | players: Map.put(game.players, id, Player.reveal(player))}
    end
  end

  defp award_points(%__MODULE__{scores: scores, players: players} = game) do
    team_one_score =
      Player.get_team_players(players, :north_south)
      |> Player.get_score()

    team_two_score =
      Player.get_team_players(players, :east_west)
      |> Player.get_score()

    %{
      game
      | scores:
          Map.update!(scores, :north_south, &(&1 + team_one_score))
          |> Map.update!(:east_west, &(&1 + team_two_score))
    }
  end

  defp increment_play_order(%__MODULE__{play_order: [last | rest]} = game) do
    %{game | play_order: Enum.concat(rest, [last]), current_player: 0}
  end

  defp deal_cards(%__MODULE__{players: players, play_order: play_order} = game, shuffle \\ false) do
    deck = if shuffle, do: Enum.shuffle(game.deck), else: game.deck

    dealt_players =
      Enum.chunk_every(deck, 4)
      |> Enum.zip()
      |> Enum.zip(play_order)
      |> Enum.map(fn {hand, id} ->
        Player.receive_cards(players[id], Tuple.to_list(hand))
      end)

    %{
      game
      | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.id, &1))
    }
  end

  defp start_bidding(game) do
    %{game | state: :bidding}
  end

  defp zip(teams, players \\ [])
  defp zip([[], team_two], players), do: Enum.concat(players, team_two)
  defp zip([team_one, []], players), do: Enum.concat(players, team_one)

  defp zip([[one | team_one], [two | team_two]], players) do
    zip([team_one, team_two], Enum.concat(players, [one, two]))
  end
end
