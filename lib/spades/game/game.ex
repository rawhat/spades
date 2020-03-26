defmodule Spades.Game do
  defstruct ~w(current_player dealer deck leader play_order players scores state trick)a

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
      state: :waiting,
      trick: []
    }
  end

  def add_player(
        %__MODULE__{} = game,
        %Player{} = player
      ) do
    game
    |> put_player(player)
    |> maybe_deal_cards()
    |> maybe_start_bidding()
  end

  def state_for_player(%__MODULE__{} = game, name) do
    player = Map.get(game.players, name)

    %{
      cards: player.hand.cards,
      call: player.hand.call,
      leader: game.leader,
      tricks: player.hand.tricks,
      scores: game.scores,
      current_player: game.current_player,
      play_order: game.play_order,
      state: game.state
    }
  end

  # def start_game(%__MODULE__{} = game) do
  # cond do
  # game.state == :waiting && Enum.count(game.players) == 4 ->
  # play_order =
  # Map.keys(game.players)
  # |> Enum.shuffle()

  # {:ok,
  # %{
  # deal_cards(game)
  # | state: :bidding,
  # play_order: play_order
  # }}

  # true ->
  # {:err, game}
  # end
  # end

  def make_call(
        %__MODULE__{state: :bidding} = game,
        name,
        call
      ) do
    if can_play?(game, name) do
      game
      |> update_player(name, &Player.make_call(&1, call))
      |> next_player()
      |> maybe_start_game()
    else
      game
    end
  end

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
      |> next_player()
    else
      game
    end
  end

  defp put_player(game, player) do
    %{
      game
      | players: Map.put(game.players, player.name, player),
        play_order: [player.name | game.play_order]
    }
  end

  defp maybe_deal_cards(%__MODULE__{players: players} = game) when map_size(players) == 4 do
    deal_cards(game)
  end

  defp maybe_deal_cards(game), do: game

  defp maybe_start_bidding(%__MODULE__{players: players, state: :waiting} = game)
       when map_size(players) == 4 do
    %{game | state: :bidding, play_order: Enum.reverse(game.play_order)}
  end

  defp maybe_start_bidding(game), do: game

  defp can_play?(game, name) do
    Enum.at(game.play_order, game.current_player) == name
  end

  defp next_player(game) do
    %{game | current_player: rem(game.current_player + 1, 4)}
  end

  defp update_player(game, name, func) do
    %{game | players: Map.update!(game.players, name, func)}
  end

  defp maybe_play_card(%__MODULE__{trick: []} = game, name, card) do
    %{game | trick: [{name, card}]}
    |> take_card_from_hand(name, card)
  end

  defp maybe_play_card(
         %__MODULE__{trick: [{_, lead} | _] = trick, players: players} = game,
         name,
         card
       ) do
    if lead.suit == card.suit || Player.can_play_spade?(players[name], lead.suit) do
      %{game | trick: [{name, card} | trick]}
      |> take_card_from_hand(name, card)
    else
      game
    end
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

    %{
      game
      | players: Map.update!(game.players, name, &Player.take(&1)),
        leader: Enum.find_index(game.play_order, &(&1 == name))
    }
  end

  defp maybe_award_trick(game), do: game

  defp maybe_start_game(game) do
    if Enum.all?(game.players, &(elem(&1, 1).hand.call != nil)) do
      %{game | state: :playing}
      |> deal_cards()
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
      |> deal_cards()
    else
      game
    end
  end

  defp award_points(%__MODULE__{scores: scores, players: players} = game) do
    team_one_score =
      Player.get_team_hands(players, 0)
      |> Player.get_score()

    team_two_score =
      Player.get_team_hands(players, 1)
      |> Player.get_score()

    %{game | scores: %{0 => scores[0] + team_one_score, 1 => scores[1] + team_two_score}}
  end

  defp deal_cards(%__MODULE__{deck: deck, players: players} = game) do
    dealt_players =
      Enum.chunk_every(deck, 4)
      |> Enum.zip()
      |> Enum.zip(Map.values(players))
      |> Enum.map(fn {hand, player} ->
        Player.receive_cards(player, Tuple.to_list(hand))
      end)

    %{game | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.name, &1))}
  end
end
