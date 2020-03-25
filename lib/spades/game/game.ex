defmodule Spades.Game do
  defstruct ~w(current_player dealer leader play_order players scores state trick)a

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Hand
  alias Spades.Game.Player

  def new() do
    %__MODULE__{
      current_player: 0,
      dealer: 0,
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

  def start_game(%__MODULE__{} = game) do
    cond do
      game.state == :waiting && Enum.count(game.players) == 4 ->
        play_order =
          Map.keys(game.players)
          |> Enum.shuffle()

        {:ok,
         %{
           deal_cards(game)
           | state: :bidding,
             play_order: play_order
         }}

      true ->
        {:err, game}
    end
  end

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
      |> update_player(name, fn player ->
        %{player | hand: Hand.play(player.hand, card)}
      end)
      |> add_to_trick(name, card)
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

  defp add_to_trick(game, name, card) do
    %{game | trick: [{name, card} | game.trick]}
  end

  defp maybe_award_trick(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    [lead | _] = trick

    max_spade =
      trick
      |> Enum.map(&elem(&1, 1))
      |> Card.max_spade()

    name =
      cond do
        lead.suit == :spade || max_spade != nil ->
          find_card_in_trick(trick, max_spade)

        true ->
          find_card_in_trick(trick, Card.max_of_suit(trick, lead.suit))
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
      start_game(game)
    else
      game
    end
  end

  defp maybe_end_hand(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    %{game | trick: []}
  end

  defp maybe_end_hand(game), do: game

  defp maybe_end_round(%__MODULE__{players: players} = game) do
    if Enum.all?(players, &Enum.empty?(&1.hand.cards)) do
      game
      |> award_points()
      |> deal_cards()
    else
      game
    end
  end

  defp award_points(%__MODULE__{scores: scores, players: players} = game) do
    team_one_total = 
  end

  defp find_card_in_trick(trick, card) do
    trick
    |> Enum.find(&(elem(&1, 1) == card))
    |> elem(0)
  end

  defp deal_cards(%__MODULE__{players: players} = game) do
    dealt_players =
      Enum.chunk_every(Deck.new(), 4)
      |> Enum.zip()
      |> Enum.zip(Map.values(players))
      |> Enum.map(fn {hand, player} ->
        Player.receive_cards(player, Tuple.to_list(hand))
      end)

    %{game | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.name, &1))}
  end
end
