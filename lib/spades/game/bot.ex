defmodule Spades.Game.Bot do
  use TypedStruct

  alias Spades.Game
  alias Spades.Game.Card
  alias Spades.Game.Hand
  alias Spades.Game.Player

  @card_weights 2..13
                |> Enum.concat([1])
                |> Enum.reverse()
                |> Enum.with_index()
                |> Enum.map(fn {value, index} -> {value, Enum.max([0, 1 - 0.25 * index])} end)
                |> Map.new()

  typedstruct do
    field :player, Player.t(), enforce: true
  end

  # right now, this will never blind nil
  def call(%Game{} = game, %Player{} = bot) do
    total =
      game
      |> existing_calls()
      |> Enum.sum()

    hand_score = score_hand(bot)

    has_ace_of_spades = Enum.member?(bot.hand.cards, Card.new(:spades, 1))

    teammate_call =
      bot
      |> get_teammate(game)
      |> get_teammate_call()

    case teammate_call do
      {:ok, call} when call == 0 or call == -1 ->
        # We want to either call the calculation from the hand, or we might want
        # to bump the call up because we're covering our partner's nil
        bot_call = Enum.max([hand_score, ceil(total * 3.0 / 2.0)])
        Game.make_call(game, bot.id, bot_call)

      {:ok, _} when total >= 9 and hand_score < 3 and not has_ace_of_spades ->
        # Total calls are pretty close to max, our hand scored pretty low,
        # and we don't have the ace of spades.  Probably worth trying
        # to go nil
        Game.make_call(game, bot.id, 0)

      _ when total + hand_score > 13 ->
        # We want to call more, but there just aren't enough to risk breaking
        # ourselves.  So call down to 12 just to leave the bag on the table
        Game.make_call(game, bot.id, 13 - total)

      _ ->
        # Everything looks hunky-dory, let's just call what we got from our hand
        Game.make_call(game, bot.id, hand_score)
    end
  end

  def play(%Game{} = game, %Player{hand: %Hand{call: 0}} = bot), do: play_for_nil(game, bot)
  def play(%Game{} = game, %Player{hand: %Hand{call: -1}} = bot), do: play_for_nil(game, bot)
  def play(%Game{} = game, %Player{hand: %Hand{call: _call}} = bot), do: play_to_win(game, bot)

  def play_to_win(game, bot) do
    lead_suit = get_lead_suit(game)
    trick_leader = get_trick_leader(game)
    teammate = get_teammate(bot, game)

    card =
      cond do
        # Is your teammate winning?  Play the lowest you can
        !is_nil(trick_leader) && trick_leader.player_id == teammate.id ->
          case lowest_of_suit(bot, lead_suit) do
            nil -> random_low_card(bot)
            card -> card
          end

        # Otherwise, try to win
        true ->
          winning_card(game, bot)
      end

    Game.play_card(game, bot.id, card)
  end

  def play_for_nil(%Game{trick: trick} = game, %Player{hand: %Hand{cards: cards}} = bot) do
    card =
      case trick do
        # Empty trick?  This probably only happens if you're nil and going first,
        # or if you got broken.  So we may want to check for that to see if you
        # want to try to break/bag them out.
        [] ->
          random_low_card(bot)

        [%{card: lead} | _] ->
          has_suit = Enum.any?(cards, &(&1.suit == lead.suit))

          max_spade =
            trick
            |> Enum.map(& &1.card)
            |> Enum.filter(&(&1.suit == :spades))
            |> Enum.max(&Card.compare/2, fn -> nil end)

          case {has_suit, max_spade} do
            {true, _} ->
              cards_of_suit =
                cards
                |> Enum.filter(&(&1.suit == lead.suit))

              closest_to(lead, cards_of_suit)

            {false, nil} ->
              not_spades =
                cards
                |> Enum.filter(&(&1.suit != :spades))
                |> Card.sorted_by_value()
                |> Enum.reverse()

              case not_spades do
                [low | _] -> low
                _ -> random_high_card(bot)
              end

            {false, spade} ->
              spades = Enum.filter(cards, &(&1.suit == :spades))

              case spades do
                [] -> random_high_card(bot)
                s -> closest_to(spade, s)
              end
          end
      end

    Game.play_card(game, bot.id, card)
  end

  def get_teammate(%Player{position: position}, %Game{
        player_position: player_position,
        players: players
      }) do
    partner =
      case position do
        :north -> :south
        :south -> :north
        :east -> :west
        :west -> :east
      end

    player_id = Map.get(player_position, partner)
    Map.get(players, player_id)
  end

  def existing_calls(%Game{players: players}) do
    players
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(& &1.hand)
    |> Stream.filter(&(!is_nil(&1)))
    |> Stream.map(& &1.call)
    |> Stream.filter(&(!is_nil(&1)))
    |> Enum.to_list()
  end

  def get_teammate_call(%Player{hand: %Hand{call: call}}) when not is_nil(call), do: {:ok, call}
  def get_teammate_call(_), do: :error

  def score_hand(%Player{hand: %Hand{cards: cards}}) do
    cards
    |> Enum.map(& &1.value)
    |> Enum.map(&Map.get(@card_weights, &1))
    |> Enum.sum()
    |> ceil()
  end

  def cards_remaining(%Game{players: players}) do
    players
    |> Map.values()
    |> Enum.flat_map(& &1.hand.cards)
  end

  def get_cards_played(%Game{deck: deck} = game) do
    player_cards = cards_remaining(game)

    deck
    |> MapSet.new()
    |> MapSet.difference(MapSet.new(player_cards))
    |> MapSet.to_list()
  end

  def get_lead_suit(%Game{trick: []}), do: nil
  def get_lead_suit(%Game{trick: [%{card: card} | _]}), do: card.suit

  def get_trick_leader(%Game{trick: trick}) do
    case Enum.split_with(trick, fn t -> t.card.suit == :spades end) do
      {[], []} ->
        nil

      {[], [lead | _] = cards} ->
        Card.max_of_suit(cards, lead.card.suit)

      {spades, _} ->
        Card.max_spade(spades)
    end
  end

  def winning_card(
        %Game{trick: trick, spades_broken: spades_broken} = game,
        %Player{hand: %Hand{cards: cards}} = bot
      ) do
    case trick do
      [] ->
        higher_cards =
          ordered_cards_by_value(bot)
          |> Enum.filter(&(spades_broken || &1.suit != :spades))
          |> Enum.drop_while(fn card ->
            Card.compare(card, highest_unseen_of_suit(game, card.suit))
          end)

        case higher_cards do
          [card | _] -> card
          [] -> random_low_card(bot)
        end

      [%{card: lead} | _] ->
        case highest_of_suit(bot, lead.suit) do
          nil ->
            spade = outspade(game, bot)

            if !is_nil(spade) do
              spade
            else
              random_low_card(bot)
            end

          card ->
            if Card.compare(card, lead) do
              lowest_of_suit(bot, lead.suit)
            else
              card
            end
        end
    end
  end

  def highest_unseen_of_suit(%Game{} = game, suit) do
    game
    |> cards_remaining()
    |> Enum.filter(&(&1.suit == suit))
    |> Enum.max(&Card.compare/2, fn -> nil end)
  end

  def highest_of_suit(%Player{hand: %Hand{cards: cards}}, suit) do
    cards
    |> Enum.filter(&(&1.suit == suit))
    |> Enum.max(&Card.compare/2, fn -> nil end)
  end

  def lowest_of_suit(%Player{hand: %Hand{cards: cards}}, suit) do
    cards
    |> Enum.filter(&(&1.suit == suit))
    |> Enum.min(&Card.compare/2, fn -> nil end)
  end

  def ordered_cards_by_value(%Player{hand: %Hand{cards: cards}}) do
    Card.sorted_by_value(cards)
  end

  def outspade(%Game{trick: trick}, %Player{} = bot) do
    max_trick_spade =
      trick
      |> Enum.map(& &1.card)
      |> Enum.filter(&(&1.suit == :spades))
      |> Enum.max(&Card.compare/2, fn -> nil end)

    case max_trick_spade do
      nil ->
        lowest_of_suit(bot, :spades)

      trick_spade ->
        next_highest =
          bot
          |> ordered_cards_by_value()
          |> Enum.filter(&(&1.suit == :spades))
          |> Enum.drop_while(&Card.compare(&1, trick_spade))

        case next_highest do
          [] -> random_low_card(bot)
          [card | _] -> card
        end
    end
  end

  def random_low_card(%Player{hand: %Hand{cards: _cards}} = bot) do
    ordered_cards = ordered_cards_by_value(bot)

    case Enum.filter(ordered_cards, &(&1.suit != :spades)) do
      [low | _] -> low
      # Player only has spades, so pick the lowest
      [] -> Enum.at(ordered_cards, 0)
    end
  end

  def random_high_card(%Player{hand: %Hand{cards: _cards}} = bot) do
    ordered_cards =
      bot
      |> ordered_cards_by_value()
      |> Enum.reverse()

    case Enum.filter(ordered_cards, &(&1.suit != :spades)) do
      [high | _] -> high
      # Player only has spades, so pick the highest
      [] -> Enum.at(ordered_cards, 0)
    end
  end

  def closest_to(card, other_cards) do
    lower =
      other_cards
      |> Enum.take_while(&Card.compare(&1, card))

    case lower do
      [card | _] ->
        card

      # We might have been broken :(
      [] ->
        other_cards
        |> Card.sorted_by_value()
        |> Enum.at(-1)
    end
  end

  # TODO:  remove
  def read_weights(), do: @card_weights
end
