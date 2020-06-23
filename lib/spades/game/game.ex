defmodule Spades.Game do
  use TypedStruct

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Event
  alias Spades.Game.Hand
  alias Spades.Game.Player

  @type score :: %{bags: integer(), points: integer()}
  @type scores :: %{:north_south => score(), :east_west => score()}
  @type public_score :: %{:north_south => integer(), :east_west => integer()}
  @type trick :: %{:id => String.t(), :card => Card.t()}
  @type state :: :waiting | :bidding | :playing
  @type player_map :: %{integer() => Player.t()}
  @type player_state :: %{
          call: Hand.call() | nil,
          cards: list(Card.t()),
          current_player: integer(),
          id: String.t(),
          last_trick: list(trick()),
          name: String.t(),
          players: list(Player.public_player()),
          revealed: boolean(),
          scores: public_score(),
          spades_broken: boolean(),
          state: state(),
          team: Player.team(),
          trick: list(trick()),
          tricks: integer() | nil
        }
  @type public_state :: %{
          current_player: integer(),
          id: String.t(),
          last_trick: list(trick()),
          name: String.t(),
          players: list(Player.public_player()),
          scores: public_score(),
          spades_broken: boolean(),
          state: state(),
          trick: list(trick())
        }
  @type error :: {:error, t(), String.t()}
  @type game :: {:ok, t()} | error()
  @type with_events :: {t(), list(Event.t())}
  @type return :: with_events() | error()
  @type input :: t() | return()

  typedstruct do
    field :current_player, integer(), default: 0
    field :deck, list(Card.t()), enforce: true
    field :id, String.t(), enforce: true
    field :name, String.t(), enforce: true
    field :play_order, list(integer()), default: []
    field :players, player_map(), default: Map.new()

    field :scores, scores(),
      default:
        Map.new([
          {:north_south, %{points: 0, bags: 0}},
          {:east_west, %{points: 0, bags: 0}}
        ])

    field :spades_broken, boolean(), default: false
    field :state, state(), default: :waiting
    field :trick, list(trick()), default: []
    field :last_trick, list(trick()), default: []
    field :events, list(Event.t()), default: []
  end

  #################################
  #         Public API            #
  #################################

  @spec new(String.t(), String.t(), list(Card.t()) | nil) :: t()
  def new(id, name, deck \\ Deck.new()) when is_binary(id) do
    %__MODULE__{
      deck: deck,
      id: id,
      name: name
    }
  end

  @spec add_player(input(), Player.t()) :: return()
  def add_player(
        %__MODULE__{} = game,
        %Player{} = player
      ) do
    game
    |> put_player(player)
    |> deal_cards()
    |> start_bidding()
    |> chain()
  end

  def add_player({%__MODULE__{} = game, events}, %Player{} = player),
    do: add_player(%{game | events: events}, player)

  def add_player({:error, _game, _reason} = with_error, _player), do: with_error

  @spec reveal_cards(input(), String.t()) :: return()
  def reveal_cards(
        %__MODULE__{state: :bidding} = game,
        id
      ) do
    case Map.get(game.players, id) do
      %Player{hand: %Hand{revealed: false}} ->
        reveal_player_card(game, id)
        |> chain()

      _ ->
        {:error, game, "#{id} cannot reveal"}
    end
  end

  def reveal_cards({%__MODULE__{} = game, events}, id),
    do: reveal_cards(%{game | events: events}, id)

  def reveal_cards({:error, _game, _reason} = with_error, _id), do: with_error

  def reveal_cards(game, id), do: {:error, game, "invalid game state for #{id} to reveal"}

  @spec make_call(input(), String.t(), Hand.call()) :: return()
  def make_call(
        %__MODULE__{state: :bidding} = game,
        id,
        call
      ) do
    if can_play?(game, id) do
      game
      |> call(id, call)
      |> next_player()
      |> start_game()
      |> chain()
    else
      {:error, game, "player #{id} cannot make call"}
    end
  end

  def make_call({%__MODULE__{} = game, events}, id, call),
    do: make_call(%{game | events: events}, id, call)

  def make_call({:error, _game, _reason} = with_error, _id, _call), do: with_error

  @spec play_card(input(), String.t(), Card.t()) :: return()
  def play_card(
        %__MODULE__{state: :playing} = game,
        id,
        %Card{} = card
      ) do
    if can_play?(game, id) do
      game
      |> play(id, card)
      |> next_player()
      |> award_trick()
      |> end_hand()
      |> end_round()
      |> chain()
    else
      {:error, game, "#{id} cannot play card"}
    end
  end

  def play_card({%__MODULE__{} = game, events}, id, %Card{} = card),
    do: play_card(%{game | events: events}, id, card)

  def play_card({:error, _game, _reason} = with_error, _id, _card), do: with_error

  def play_card(game, id, _card), do: {:error, game, "invalid game state for #{id} to play card"}

  @spec state_for_player(t(), integer()) :: state() | public_state()
  def state_for_player(%__MODULE__{} = game, id) do
    player = Map.get(game.players, id)

    if player == nil do
      state(game)
    else
      revealed = player.hand != nil && player.hand.revealed

      %{
        call: if(player.hand != nil, do: player.hand.call, else: nil),
        cards: Player.sorted_hand(player),
        current_player: game.current_player,
        id: game.id,
        last_trick: game.last_trick,
        name: game.name,
        players: get_player_list(game),
        revealed: revealed,
        scores: get_public_scores(game),
        spades_broken: game.spades_broken,
        state: game.state,
        team: player.team,
        trick: game.trick,
        tricks: if(player.hand != nil, do: player.hand.tricks, else: nil)
      }
    end
  end

  @spec state(t()) :: public_state()
  def state(%__MODULE__{} = game) do
    %{
      current_player: game.current_player,
      id: game.id,
      last_trick: game.last_trick,
      name: game.name,
      players: get_player_list(game),
      scores: get_public_scores(game),
      spades_broken: game.spades_broken,
      state: game.state,
      trick: game.trick
    }
  end

  ###########################

  @spec chain(game()) :: return()
  defp chain({:ok, %__MODULE__{events: events} = game}), do: {%{game | events: []}, events}
  defp chain({:error, game, err}), do: {:error, %{game | events: []}, err}

  @spec get_player_list(t()) :: list(Player.public_player())
  defp get_player_list(game) do
    Stream.map(game.play_order, &Map.get(game.players, &1))
    |> Stream.map(&Player.to_public/1)
    |> Enum.to_list()
  end

  @spec put_player(t(), Player.t()) :: game()
  defp put_player(%__MODULE__{players: players} = game, player) when map_size(players) == 4,
    do: {:error, game, "cannot add #{player.name} because game is full"}

  defp put_player(%__MODULE__{players: players} = game, %Player{id: id})
       when is_map_key(players, id),
       do: {:error, game, "player #{id} is already in game"}

  defp put_player(%__MODULE__{players: players} = game, player) do
    if Enum.count(players, fn {_, p} -> p.team == player.team end) == 2 do
      {:error, game, "cannot add #{player.name} to #{to_string(player.team)} because it is full"}
    else
      new_players = Map.put(players, player.id, player)

      play_order =
        Enum.concat(game.play_order, [player.id])
        |> Enum.split_with(&(Map.get(new_players, &1).team == :north_south))
        |> Tuple.to_list()
        |> zip()

      %__MODULE__{
        game
        | players: new_players,
          play_order: play_order
      }
      |> ok()
    end
  end

  @spec start_bidding(game()) :: game()
  defp start_bidding({:ok, %__MODULE__{players: players, state: :waiting} = game})
       when map_size(players) == 4 do
    set_bidding(game)
    |> add_event(:state_changed, %{old: :waiting, new: :bidding})
    |> ok()
  end

  defp start_bidding(result), do: result

  defp set_bidding(%__MODULE__{} = game), do: %{game | state: :bidding}
  defp set_bidding({:ok, %__MODULE__{} = game}), do: %{game | state: :bidding} |> ok()

  @spec can_play?(t(), String.t()) :: boolean()
  defp can_play?(game, id) do
    Enum.at(game.play_order, game.current_player) == id
  end

  @spec next_player(game()) :: game()
  defp next_player({:ok, %__MODULE__{} = game}) do
    # TODO
    %__MODULE__{game | current_player: rem(game.current_player + 1, 4)}
    |> ok()
  end

  defp next_player(game), do: game

  @spec call(t(), String.t(), Hand.call()) :: game()
  def call(
        %__MODULE__{} = game,
        id,
        call
      ) do
    if can_play?(game, id) && Player.can_call?(game.players[id], call) do
      %__MODULE__{game | players: Map.update!(game.players, id, &Player.make_call(&1, call))}
      |> add_event(:called, %{player: id, call: call})
      |> ok()
    else
      {:error, game, "#{id} cannot call right now"}
    end
  end

  @spec play(t(), String.t(), Card.t()) :: game()
  defp play(%__MODULE__{trick: [], players: players} = game, id, card) do
    if Player.can_play?(players[id], card, nil, game.spades_broken) do
      %__MODULE__{game | trick: [%{id: id, card: card}]}
      |> take_card_from_hand(id, card)
      |> spades_broken(card)
      |> add_event(:played_card, %{player: id, card: card})
      |> ok()
    else
      {:error, game, "#{id} cannot play #{to_string(card)}"}
    end
  end

  defp play(
         %__MODULE__{trick: [%{card: lead} | _] = trick, players: players} = game,
         id,
         card
       ) do
    if Player.can_play?(players[id], card, lead, game.spades_broken) do
      %__MODULE__{game | trick: Enum.concat(trick, [%{id: id, card: card}])}
      |> take_card_from_hand(id, card)
      |> spades_broken(card)
      |> add_event(:played_card, %{player: id, card: card})
      |> ok()
    else
      {:error, game, "#{id} cannot play #{to_string(card)}, and #{to_string(lead)} was lead"}
    end
  end

  defp play(game, id, _card), do: {:error, game, "invalid game state for #{id} to play card"}

  @spec spades_broken(t(), Card.t()) :: t()
  defp spades_broken(game, card) do
    %__MODULE__{game | spades_broken: card.suit == :spades || game.spades_broken}
  end

  @spec take_card_from_hand(t(), String.t(), Card.t()) :: t()
  defp take_card_from_hand(game, id, card) do
    %__MODULE__{game | players: Map.update!(game.players, id, &Player.play_card(&1, card))}
  end

  @spec award_trick(game()) :: game()
  defp award_trick({:ok, %__MODULE__{trick: trick} = game}) when length(trick) == 4 do
    [%{card: lead} | _] = trick

    max_spade = Card.max_spade(trick)

    id =
      if lead.suit == :spade || max_spade != nil do
        Map.get(max_spade, :id)
      else
        Card.max_of_suit(trick, lead.suit)
        |> Map.get(:id)
      end

    winner = Enum.find_index(game.play_order, &(&1 == id))

    %__MODULE__{
      game
      | players: Map.update!(game.players, id, &Player.take(&1)),
        current_player: winner
    }
    |> add_event(:awarded_trick, %{winner: id})
    |> ok()
  end

  defp award_trick(game), do: game

  @spec start_game(game()) :: game()
  defp start_game({:ok, game}) do
    if Enum.all?(game.players, &(elem(&1, 1).hand.call != nil)) do
      %__MODULE__{game | state: :playing}
      |> add_event(:state_changed, %{old: :bidding, new: :playing})
    else
      {:ok, game}
    end
    |> ok()
  end

  defp start_game(game), do: game

  @spec end_hand(game()) :: game()
  defp end_hand({:ok, %__MODULE__{trick: trick} = game}) when length(trick) == 4 do
    %__MODULE__{game | trick: [], last_trick: trick}
    |> add_event(:hand_ended, %{})
    |> ok()
  end

  defp end_hand(game), do: game

  @spec end_round(game()) :: return()
  defp end_round({:ok, %__MODULE__{players: players} = game}) do
    all_empty =
      Enum.all?(players, fn {_, player} ->
        Enum.empty?(player.hand.cards)
      end)

    if all_empty do
      game
      |> clear_last_trick()
      |> award_points()
      |> increment_play_order()
      |> deal(true)
      |> set_bidding()
      |> add_event(:round_ended, %{})
      |> ok()
    else
      ok(game)
    end
  end

  defp end_round(game), do: game

  defp clear_last_trick(%__MODULE__{} = game) do
    %__MODULE__{game | last_trick: []}
  end

  @spec reveal_player_card(t(), String.t()) :: game()
  defp reveal_player_card(game, id) do
    player = Map.get(game.players, id)

    if player == nil do
      {:error, game, "no player for #{id} in the game"}
    else
      %__MODULE__{game | players: Map.put(game.players, id, Player.reveal(player))}
      |> add_event(:revealed_cards, %{player: id})
      |> ok()
    end
  end

  @spec award_points(t()) :: t()
  defp award_points(
         %__MODULE__{
           scores: %{north_south: north_south, east_west: east_west},
           players: players
         } = game
       ) do
    north_south_score =
      Player.get_team_players(players, :north_south)
      |> Player.get_score()
      |> Player.update_score(north_south)

    east_west_score =
      Player.get_team_players(players, :east_west)
      |> Player.get_score()
      |> Player.update_score(east_west)

    %__MODULE__{
      game
      | scores: %{
          north_south: north_south_score,
          east_west: east_west_score
        }
    }
  end

  @spec increment_play_order(t()) :: t()
  defp increment_play_order(%__MODULE__{play_order: [last | rest]} = game) do
    %__MODULE__{game | play_order: Enum.concat(rest, [last]), current_player: 0}
  end

  @spec deal_cards(game()) :: game()
  defp deal_cards(game, shuffle \\ false)

  defp deal_cards({:ok, %__MODULE__{players: players} = game}, shuffle)
       when map_size(players) == 4,
       do: deal(game, shuffle)

  defp deal_cards(game, _shuffle), do: game

  defp deal(
         %__MODULE__{players: players, play_order: play_order} = game,
         shuffle
       ) do
    deck =
      if shuffle,
        do: Enum.reduce(1..10, game.deck, fn _, deck -> Enum.shuffle(deck) end),
        else: game.deck

    dealt_players =
      Enum.chunk_every(deck, 4)
      |> Enum.zip()
      |> Enum.zip(play_order)
      |> Enum.map(fn {hand, id} ->
        Player.receive_cards(players[id], Tuple.to_list(hand))
      end)

    %__MODULE__{
      game
      | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.id, &1))
    }
    |> add_event(:dealt_cards, %{})
    |> ok()
  end

  defp zip(teams, players \\ [])
  defp zip([[], team_two], players), do: Enum.concat(players, team_two)
  defp zip([team_one, []], players), do: Enum.concat(players, team_one)

  @spec zip(list(list(Player.t())), list(Player.t())) :: list(Player.t())
  defp zip([[one | team_one], [two | team_two]], players) do
    zip([team_one, team_two], Enum.concat(players, [one, two]))
  end

  defp get_public_scores(%__MODULE__{scores: %{north_south: north_south, east_west: east_west}}) do
    %{
      north_south: north_south.points + north_south.bags,
      east_west: east_west.points + east_west.bags
    }
  end

  @spec add_event(t(), Event.event_type(), map()) :: t()
  defp add_event(%__MODULE__{events: events} = game, type, data) do
    %{game | events: Enum.concat(events, [Event.create_event(type, data)])}
  end

  defp add_event({:ok, %__MODULE__{events: events} = game}, type, data) do
    {:ok, %{game | events: Enum.concat(events, [Event.create_event(type, data)])}}
  end

  defp ok(game) when is_struct(game), do: {:ok, game}
  defp ok(result), do: result
end
