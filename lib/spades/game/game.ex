defmodule Spades.Game do
  defstruct ~w(advance current_player dealer deck leader play_order players scores spades_broken state trick)a

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Player

  def new(deck \\ Deck.new()) do
    %__MODULE__{
      current_player: 0,
      dealer: 0,
      deck: deck,
      leader: 0,
      players: %{},
      play_order: [],
      scores: %{0 => 0, 1 => 0},
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

  def state_for_player(%__MODULE__{} = game, name) do
    player = Map.get(game.players, name)

    if player == nil do
      %{}
    else
      %{
        cards: if(player.hand == nil, do: [], else: player.hand.cards),
        call: if(player.hand == nil, do: -2, else: player.hand.call),
        leader: game.leader,
        tricks: if(player.hand == nil, do: -1, else: player.hand.tricks),
        scores: game.scores,
        current_player: game.current_player,
        play_order: game.play_order,
        spades_broken: game.spades_broken,
        state: game.state,
        trick: game.trick
      }
    end
  end

  def make_call(
        %__MODULE__{state: :bidding} = game,
        name,
        call
      ) do
    if can_play?(game, name) do
      game
      |> maybe_make_call(name, call)
      |> next_player()
      |> maybe_start_game()
    else
      game
    end
  end

  def make_call(game, _name, _call), do: game

  def play_card(
        %__MODULE__{state: :playing} = game,
        name,
        card
      ) do
    if can_play?(game, name) do
      game
      |> maybe_play_card(name, card)
      |> maybe_award_trick()
      |> maybe_end_hand()
      |> maybe_end_round()
    else
      game
    end
  end

  def play_card(game, _name, _card), do: game

  defp maybe_put_player(%__MODULE__{players: players} = game, _player)
       when map_size(players) >= 4,
       do: game

  defp maybe_put_player(game, player) do
    %{
      game
      | players: Map.put(game.players, player.name, player),
        play_order: Enum.concat(game.play_order, [player.name])
    }
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

  defp can_play?(game, name) do
    Enum.at(game.play_order, game.current_player) == name
  end

  defp next_player(%__MODULE__{advance: true} = game) do
    %{game | current_player: rem(game.current_player + 1, 4), advance: false}
  end

  defp next_player(game), do: game

  def maybe_make_call(
        %__MODULE__{play_order: play_order, current_player: current_player} = game,
        name,
        call
      ) do
    if Enum.at(play_order, current_player) == name do
      %{game | players: Map.update!(game.players, name, &Player.make_call(&1, call))}
      |> advance()
    else
      game
    end
  end

  defp maybe_play_card(%__MODULE__{trick: [], players: players} = game, name, card) do
    if Player.can_play?(players[name], card, nil, game.spades_broken) do
      %{game | trick: [{name, card}]}
      |> take_card_from_hand(name, card)
      |> spades_broken(card)
      |> advance()
    else
      game
    end
  end

  defp maybe_play_card(
         %__MODULE__{trick: [{_, lead} | _] = trick, players: players} = game,
         name,
         card
       ) do
    if Player.can_play?(players[name], card, lead, game.spades_broken) do
      %{game | trick: [{name, card} | trick]}
      |> take_card_from_hand(name, card)
      |> spades_broken(card)
      |> advance()
    else
      game
    end
  end

  defp spades_broken(game, card) do
    %{game | spades_broken: card.suit == :spades || game.spades_broken}
  end

  defp take_card_from_hand(game, name, card) do
    %{game | players: Map.update!(game.players, name, &Player.play_card(&1, card))}
  end

  defp maybe_award_trick(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    [{_, lead} | _] = trick

    max_spade = Card.max_spade(trick)

    name =
      cond do
        lead.suit == :spade || max_spade != nil -> elem(max_spade, 0)
        true -> elem(Card.max_of_suit(trick, lead.suit), 0)
      end

    winner = Enum.find_index(game.play_order, &(&1 == name))

    %{
      game
      | players: Map.update!(game.players, name, &Player.take(&1)),
        leader: winner,
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

  defp award_points(%__MODULE__{scores: scores, players: players} = game) do
    team_one_score =
      Player.get_team_players(players, 0)
      |> Player.get_score()

    team_two_score =
      Player.get_team_players(players, 1)
      |> Player.get_score()

    %{game | scores: %{0 => scores[0] + team_one_score, 1 => scores[1] + team_two_score}}
  end

  defp increment_play_order(%__MODULE__{play_order: play_order} = game) do
    updated_play_order =
      Enum.slice(play_order, 1..3)
      |> Enum.concat(Enum.slice(play_order, 0..1))

    %{game | play_order: updated_play_order}
  end

  defp deal_cards(%__MODULE__{players: players, play_order: play_order} = game, shuffle \\ false) do
    deck = if shuffle, do: Enum.shuffle(game.deck), else: game.deck

    dealt_players =
      Enum.chunk_every(deck, 4)
      |> Enum.zip()
      |> Enum.zip(play_order)
      |> Enum.map(fn {hand, player} ->
        Player.receive_cards(players[player], Tuple.to_list(hand))
      end)

    %{
      game
      | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.name, &1))
    }
  end

  defp start_bidding(game) do
    %{game | state: :bidding}
  end
end
