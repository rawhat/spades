defmodule Spades.Game do
  use TypedStruct

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Hand
  alias Spades.Game.Player

  @type scores :: %{:north_south => integer(), :east_west => integer()}
  @type trick :: %{:id => String.t(), :card => Card.card()}
  @type state :: :waiting | :bidding | :playing
  @type player_map :: %{String.t() => Player.player()}

  @type player_state :: %{
          call: Hand.call() | nil,
          cards: list(Card.card()),
          current_player: integer(),
          id: String.t(),
          name: String.t(),
          players: list(Player.public_player()),
          revealed: boolean(),
          scores: scores(),
          spades_broken: boolean(),
          state: state(),
          team: Player.team(),
          trick: list(trick()),
          tricks: integer() | nil
        }
  @type public_state :: %{
          current_player: integer(),
          id: String.t(),
          name: String.t(),
          players: list(Player.public_player()),
          scores: scores(),
          spades_broken: boolean(),
          state: state(),
          trick: list(trick())
        }

  typedstruct do
    field :advance, boolean() | nil
    field :current_player, integer()
    field :deck, list(Card.t()), enforce: true
    field :id, String.t(), enforce: true
    field :name, String.t(), enforce: true
    field :players, list(Player.public_player())
    field :play_order, list(String.t())
    field :revealed, boolean()
    field :scores, scores()
    field :spades_broken, boolean()
    field :state, state()
    field :team, Player.team()
    field :trick, list(trick())
    field :tricks, integer() | nil
  end

  @spec new(String.t(), String.t(), list(Card.card()) | nil) :: t()
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

  @spec add_player(t(), Player.player()) :: t()
  def add_player(
        %__MODULE__{} = game,
        %Player{} = player
      ) do
    game
    |> maybe_put_player(player)
    |> maybe_deal_cards()
    |> maybe_start_bidding()
  end

  @spec state_for_player(t(), String.t()) :: state() | public_state()
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
        name: game.name,
        players: get_player_list(game),
        revealed: revealed,
        scores: game.scores,
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
      name: game.name,
      players: get_player_list(game),
      scores: game.scores,
      spades_broken: game.spades_broken,
      state: game.state,
      trick: game.trick
    }
  end

  @spec get_player_list(t()) :: list(Player.public_player())
  defp get_player_list(game) do
    Stream.map(game.play_order, &Map.get(game.players, &1))
    |> Stream.map(&Player.to_public/1)
    |> Enum.to_list()
  end

  @spec reveal_cards(t(), String.t()) :: t()
  def reveal_cards(
        %__MODULE__{state: :bidding} = game,
        id
      ) do
    if can_play?(game, id) do
      reveal_player_card(game, id)
    else
      game
    end
  end

  def reveal_cards(game, _name), do: game

  @spec make_call(t(), String.t(), Hand.call()) :: t()
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

  @spec play_card(t(), String.t(), Card.card()) :: t()
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

  @spec maybe_put_player(t(), Player.player()) :: t()
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

  @spec advance(t()) :: t()
  defp advance(game) do
    %{game | advance: true}
  end

  @spec maybe_deal_cards(t()) :: t()
  defp maybe_deal_cards(%__MODULE__{players: players} = game) when map_size(players) == 4 do
    deal_cards(game)
  end

  defp maybe_deal_cards(game), do: game

  @spec maybe_start_bidding(t()) :: t()
  defp maybe_start_bidding(%__MODULE__{players: players, state: :waiting} = game)
       when map_size(players) == 4 do
    %{game | state: :bidding}
  end

  defp maybe_start_bidding(game), do: game

  @spec can_play?(t(), String.t()) :: boolean()
  defp can_play?(game, id) do
    Enum.at(game.play_order, game.current_player) == id
  end

  @spec next_player(t()) :: t()
  defp next_player(%__MODULE__{advance: true} = game) do
    # TODO
    %{game | current_player: rem(game.current_player + 1, 4), advance: false}
  end

  defp next_player(game), do: game

  @spec maybe_make_call(t(), String.t(), Hand.call()) :: t()
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

  @spec maybe_play_card(t(), String.t(), Card.card()) :: t()
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

  defp maybe_play_card(game, _id, _card), do: game

  @spec spades_broken(t(), Card.card()) :: t()
  defp spades_broken(game, card) do
    %{game | spades_broken: card.suit == :spades || game.spades_broken}
  end

  @spec take_card_from_hand(t(), String.t(), Card.card()) :: t()
  defp take_card_from_hand(game, id, card) do
    %{game | players: Map.update!(game.players, id, &Player.play_card(&1, card))}
  end

  @spec maybe_award_trick(t()) :: t()
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

  @spec maybe_start_game(t()) :: t()
  defp maybe_start_game(game) do
    if Enum.all?(game.players, &(elem(&1, 1).hand.call != nil)) do
      %{game | state: :playing}
    else
      game
    end
  end

  @spec maybe_end_hand(t()) :: t()
  defp maybe_end_hand(%__MODULE__{trick: trick} = game) when length(trick) == 4 do
    %{game | trick: []}
  end

  defp maybe_end_hand(game), do: game

  @spec maybe_end_round(t()) :: t()
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

  @spec reveal_player_card(t(), String.t()) :: t()
  defp reveal_player_card(game, id) do
    player = Map.get(game.players, id)

    if player == nil do
      game
    else
      %{game | players: Map.put(game.players, id, Player.reveal(player))}
    end
  end

  @spec award_points(t()) :: t()
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

  @spec increment_play_order(t()) :: t()
  defp increment_play_order(%__MODULE__{play_order: [last | rest]} = game) do
    %{game | play_order: Enum.concat(rest, [last]), current_player: 0}
  end

  @spec deal_cards(t()) :: t()
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

  @spec start_bidding(t()) :: t()
  defp start_bidding(game) do
    %{game | state: :bidding}
  end

  defp zip(teams, players \\ [])
  defp zip([[], team_two], players), do: Enum.concat(players, team_two)
  defp zip([team_one, []], players), do: Enum.concat(players, team_one)

  @spec zip(list(list(Player.player())), list(Player.player())) :: list(Player.player())
  defp zip([[one | team_one], [two | team_two]], players) do
    zip([team_one, team_two], Enum.concat(players, [one, two]))
  end
end
