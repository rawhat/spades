import dropWhile from "lodash/dropWhile";
import takeWhile from "lodash/takeWhile";
import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createAction, createSlice, PayloadAction } from "@reduxjs/toolkit";

import { RootState } from "../../app/store";
import { get } from "../../app/client";
import { selectUsername } from "../user/userSlice";

type CalledEvent = {
  type: "called";
  data: {
    player: string;
    call: number;
  };
};

type StateChangedEvent = {
  type: "state_changed";
  data: {
    old: GameState;
    new: GameState;
  };
};

export type PlayedCardEvent = {
  type: "played_card";
  data: {
    player: string;
    card: Card;
  };
};

type HandEndedEvent = {
  type: "hand_ended";
  data: {};
};

type RoundEndedEvent = {
  type: "round_ended";
  data: {};
};

type AwardedTrickEvent = {
  type: "awarded_trick";
  data: {
    winner: string;
  };
};

type RevealedCardsEvent = {
  type: "revealed_cards";
  data: {
    player: string;
  };
};

type DealtCardsEvent = {
  type: "dealt_cards";
  data: {};
};

export type Event =
  | CalledEvent
  | StateChangedEvent
  | PlayedCardEvent
  | HandEndedEvent
  | RoundEndedEvent
  | AwardedTrickEvent
  | RevealedCardsEvent
  | DealtCardsEvent;

type IsEvent<T, N> = T extends { type: N } ? T : never;

export function isEvent<T extends Event, K extends T["type"]>(type: K) {
  return (event: T): event is IsEvent<T, K> => {
    return event.type === type;
  };
}

interface GameState {
  connected: boolean;
  error?: string;
  game?: GameStatus;
  playerState?: PlayerStatus;
  events?: Event[];
}

export enum Team {
  NorthSouth = "north_south",
  EastWest = "east_west",
}

export enum Position {
  North = "north",
  South = "south",
  East = "east",
  West = "west",
}

export interface GameStatus {
  id: string;
  last_trick: PlayedCard[];
  name: string;
  scores: Record<Team, number>;
  player_position: Record<Position, string>;
  players: PublicPlayer[];
  state: State;
  trick: PlayedCard[];
  current_player: string;
}

export interface PlayerStatus extends GameStatus {
  cards: Card[];
  call: number | null;
  position: Position;
  tricks: number | null;
  trick: PlayedCard[];
  team: Team;
  revealed: boolean;
}

export enum State {
  Waiting = "waiting",
  Bidding = "bidding",
  Playing = "playing",
}

export enum Suit {
  Clubs = "clubs",
  Diamonds = "diamonds",
  Hearts = "hearts",
  Spades = "spades",
}

export interface Card {
  suit: Suit;
  value: number;
}

export interface PlayedCard {
  card: Card;
  player_id: string;
}

export interface PublicPlayer {
  call: number;
  cards: number;
  id: string;
  name: string;
  position: Position;
  revealed: boolean;
  team: Team;
  tricks: number;
}

const initialState: GameState = {
  connected: false,
};

export const gameSlice = createSlice({
  name: "game",
  initialState,
  reducers: {
    setConnected: (state) => {
      state.connected = true;
    },
    setDisconnected: (state) => {
      state.connected = false;
    },
    setError: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
    },
    clearError: (state) => {
      delete state.error;
    },
    setGameState: (state, action: PayloadAction<GameStatus>) => {
      state.game = action.payload;
    },
    setPlayerState: (state, action: PayloadAction<PlayerStatus>) => {
      state.playerState = action.payload;
    },
    setEvents: (state, action: PayloadAction<Event[]>) => {
      state.events = action.payload;
    },
    clearEvents: (state) => {
      state.events = undefined;
    },
  },
});

export const {
  clearError,
  clearEvents,
  setConnected,
  setDisconnected,
  setError,
  setEvents,
  setGameState,
} = gameSlice.actions;

export const loadGameState = (id: string) => async (dispatch: Dispatch) => {
  const data = await get<{ game: GameStatus }>(`/game/${id}`);
  dispatch(setGameState(data.game));
};

export const socketError = createAction<string>("game/socketError");

interface JoinGamePayload {
  id: string;
  position: Position;
  username: string;
}
export const joinGame = createAction<JoinGamePayload>("game/join");
export const observeGame = createAction<{ id: string; username?: string }>(
  "game/observe"
);

export const revealCards = createAction("game/reveal");
export const makeCall = createAction<number>("game/makeCall");
export const playCard = createAction<Card>("game/playCard");

export const { setPlayerState } = gameSlice.actions;

export default gameSlice.reducer;

export const getGameState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.game
);

export const getPlayerState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.playerState
);

export const selectGameLoaded = createSelector(
  getGameState,
  (state: GameStatus | undefined) => !!state
);

export const selectPlayers = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => playerState?.players || gameState?.players || []
);

export const selectPlayerPositions = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) =>
    playerState?.player_position || gameState?.player_position
);

export const selectPlayerCards = createSelector(
  getPlayerState,
  (player) => player?.cards
);

export const selectPlayerCardsRevealed = createSelector(
  getPlayerState,
  (player) => player?.revealed || false
);

export const selectCurrentPlayer = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState): PublicPlayer | undefined => {
    const players = playerState?.players || gameState?.players;
    const currentPlayer =
      playerState?.current_player || gameState?.current_player;
    if (players && currentPlayer) {
      return players.find((p) => p.position === currentPlayer);
    }
    return;
  }
);

export const selectGameState = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState): State | undefined =>
    playerState?.state || gameState?.state
);

export const selectTrick = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => playerState?.trick || gameState?.trick || []
);

export const selectScores = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => playerState?.scores || gameState?.scores || []
);

export const selectConnected = createSelector(
  (state: RootState) => state.game,
  (gameState) => gameState.connected
);

export const selectSelf = createSelector(
  getGameState,
  getPlayerState,
  selectUsername,
  (gameState, playerState, username) =>
    (playerState || gameState)?.players.find((p) => p.name === username)
);

// Clockwise from bottom, i.e:
//         S
//      E     W
//         N
const defaultOrder = [
  Position.North,
  Position.East,
  Position.South,
  Position.West,
];

export type TrickByPlayerId = { [playerId: string]: PlayedCard };

export const selectTrickByPlayerId = createSelector(
  selectTrick,
  (trick: PlayedCard[]): TrickByPlayerId =>
    trick.reduce((acc, obj) => ({ ...acc, [obj.player_id]: obj }), {})
);

export const selectLastTrick = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => (playerState || gameState)?.last_trick
);

export const selectEvents = createSelector(
  (state: RootState) => state.game,
  (gameState: GameState) => gameState.events ?? []
);

export const selectError = createSelector(
  (state: RootState) => state.game,
  (state) => state.error
);

export const selectPlayersById = createSelector(
  getPlayerState,
  getGameState,
  (playerState, gameState) =>
    Object.fromEntries(
      Object.values((playerState || gameState)?.players ?? {}).map((player) => [
        player.id,
        player,
      ])
    )
);

export const selectOrderedPlayers = createSelector(
  selectPlayerPositions,
  selectPlayersById,
  selectSelf,
  (playerPositions, playersById, self) => {
    const orderedPlayers = defaultOrder
      .map((position) =>
        playerPositions ? playerPositions[position] : undefined
      )
      .map((playerId) => (playerId ? playersById[playerId] : undefined));
    if (!self) {
      return orderedPlayers;
    }
    const after = takeWhile(orderedPlayers, (p) => p?.name !== self.name);
    return dropWhile(orderedPlayers, (p) => p?.name !== self.name).concat(
      after
    );
  }
);
