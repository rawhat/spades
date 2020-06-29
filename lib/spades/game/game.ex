defmodule Spades.Game do
  use TypedStruct

  alias Spades.Game.Card
  alias Spades.Game.Deck
  alias Spades.Game.Hand
  alias Spades.Game.Player

  @type scores :: %{:north_south => integer(), :east_west => integer()}
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
          last_trick: list(trick()),
          name: String.t(),
          players: list(Player.public_player()),
          scores: scores(),
          spades_broken: boolean(),
          state: state(),
          trick: list(trick())
        }
  @type error :: {:error, t(), String.t()}
  @type game :: {:ok, t()} | error()
  @type return :: t() | error()

  typedstruct do
    field :current_player, integer(), default: 0
    field :deck, list(Card.t()), enforce: true
    field :id, String.t(), enforce: true
    field :name, String.t(), enforce: true
    field :play_order, list(integer()), default: []
    field :players, player_map(), default: Map.new()
    field :scores, scores(), default: Map.new([{:north_south, 0}, {:east_west, 0}])
    field :spades_broken, boolean(), default: false
    field :state, state(), default: :waiting
    field :trick, list(trick()), default: []
    field :last_trick, list(trick()), default: []
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

  @spec add_player(t(), Player.t()) :: return()
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

  def add_player({:error, _game, _reason} = with_error, _player), do: with_error

  @spec reveal_cards(t(), String.t()) :: return()
  def reveal_cards(
        %__MODULE__{state: :bidding} = game,
        id
      ) do
    if can_play?(game, id) do
      reveal_player_card(game, id)
      |> chain()
    else
      {:error, game, "#{id} cannot reveal"}
    end
  end

  def reveal_cards({:error, _game, _reason} = with_error, _id), do: with_error

  def reveal_cards(game, id), do: {:error, game, "invalid game state for #{id} to reveal"}

  @spec make_call(t(), String.t(), Hand.call()) :: return()
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

  def make_call({:error, _game, _reason} = with_error, _id, _call), do: with_error

  @spec play_card(t(), String.t(), Card.t()) :: return()
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
      last_trick: game.last_trick,
      name: game.name,
      players: get_player_list(game),
      scores: game.scores,
      spades_broken: game.spades_broken,
      state: game.state,
      trick: game.trick
    }
  end

  ###########################

  @spec chain(game()) :: return()
  defp chain({:ok, game}), do: game
  defp chain(with_error), do: with_error

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

      {:ok,
       %__MODULE__{
         game
         | players: new_players,
           play_order: play_order
       }}
    end
  end

  @spec start_bidding(game()) :: game()
  defp start_bidding({:ok, %__MODULE__{players: players, state: :waiting} = game})
       when map_size(players) == 4 do
    {:ok, %__MODULE__{game | state: :bidding}}
  end

  defp start_bidding({:ok, %__MODULE__{players: players, state: :playing} = game})
       when map_size(players) == 4 do
    {:ok, %__MODULE__{game | state: :bidding}}
  end

  defp start_bidding(game), do: game

  @spec can_play?(t(), String.t()) :: boolean()
  defp can_play?(game, id) do
    Enum.at(game.play_order, game.current_player) == id
  end

  @spec next_player(game()) :: game()
  defp next_player({:ok, %__MODULE__{} = game}) do
    # TODO
    {:ok, %__MODULE__{game | current_player: rem(game.current_player + 1, 4)}}
  end

  defp next_player(game), do: game

  @spec call(t(), String.t(), Hand.call()) :: game()
  def call(
        %__MODULE__{} = game,
        id,
        call
      ) do
    if can_play?(game, id) do
      {:ok,
       %__MODULE__{game | players: Map.update!(game.players, id, &Player.make_call(&1, call))}}
    else
      {:error, game, "#{id} cannot call right now"}
    end
  end

  @spec play(t(), String.t(), Card.t()) :: game()
  defp play(%__MODULE__{trick: [], players: players} = game, id, card) do
    if Player.can_play?(players[id], card, nil, game.spades_broken) do
      {:ok,
       %__MODULE__{game | trick: [%{id: id, card: card}]}
       |> take_card_from_hand(id, card)
       |> spades_broken(card)}
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
      {:ok,
       %__MODULE__{game | trick: Enum.concat(trick, [%{id: id, card: card}])}
       |> take_card_from_hand(id, card)
       |> spades_broken(card)}
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
      cond do
        lead.suit == :spade || max_spade != nil ->
          Map.get(max_spade, :id)

        true ->
          Card.max_of_suit(trick, lead.suit)
          |> Map.get(:id)
      end

    winner = Enum.find_index(game.play_order, &(&1 == id))

    {:ok,
     %__MODULE__{
       game
       | players: Map.update!(game.players, id, &Player.take(&1)),
         current_player: winner
     }}
  end

  defp award_trick(game), do: game

  @spec start_game(game()) :: game()
  defp start_game({:ok, game}) do
    if Enum.all?(game.players, &(elem(&1, 1).hand.call != nil)) do
      {:ok, %__MODULE__{game | state: :playing}}
    else
      {:ok, game}
    end
  end

  defp start_game(game), do: game

  @spec end_hand(game()) :: game()
  defp end_hand({:ok, %__MODULE__{trick: trick} = game}) when length(trick) == 4 do
    {:ok, %__MODULE__{game | trick: [], last_trick: trick}}
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
      |> start_bidding()
    else
      game
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
      {:ok, %__MODULE__{game | players: Map.put(game.players, id, Player.reveal(player))}}
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

    %__MODULE__{
      game
      | scores:
          Map.update!(scores, :north_south, &(&1 + team_one_score))
          |> Map.update!(:east_west, &(&1 + team_two_score))
    }
  end

  @spec increment_play_order(t()) :: t()
  defp increment_play_order(%__MODULE__{play_order: [last | rest]} = game) do
    %__MODULE__{game | play_order: Enum.concat(rest, [last]), current_player: 0}
  end

  @spec deal_cards(game()) :: game()
  defp deal_cards(game, shuffle \\ false)

  defp deal_cards({:ok, %__MODULE__{} = game}, shuffle), do: deal(game, shuffle)

  defp deal_cards(game, _shuffle), do: game

  defp deal(
         %__MODULE__{players: players, play_order: play_order} = game,
         shuffle
       ) do
    deck = if shuffle, do: Enum.shuffle(game.deck), else: game.deck

    dealt_players =
      Enum.chunk_every(deck, 4)
      |> Enum.zip()
      |> Enum.zip(play_order)
      |> Enum.map(fn {hand, id} ->
        Player.receive_cards(players[id], Tuple.to_list(hand))
      end)

    {:ok,
     %__MODULE__{
       game
       | players: Enum.reduce(dealt_players, %{}, &Map.put(&2, &1.id, &1))
     }}
  end

  defp zip(teams, players \\ [])
  defp zip([[], team_two], players), do: Enum.concat(players, team_two)
  defp zip([team_one, []], players), do: Enum.concat(players, team_one)

  @spec zip(list(list(Player.t())), list(Player.t())) :: list(Player.t())
  defp zip([[one | team_one], [two | team_two]], players) do
    zip([team_one, team_two], Enum.concat(players, [one, two]))
  end
end
