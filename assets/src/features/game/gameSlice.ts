import dropWhile from "lodash/dropWhile";
import groupBy from "lodash/groupBy";
import takeWhile from "lodash/takeWhile";
import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createAction, createSlice, PayloadAction } from "@reduxjs/toolkit";

import { get } from "../../app/client";
import { RootState } from "../../app/store";
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

export interface GameStatus {
  id: string;
  last_trick: PlayedCard[];
  name: string;
  scores: { [team in keyof Team]: number };
  players: PublicPlayer[];
  state: State;
  trick: PlayedCard[];
  current_player: number;
}

export interface PlayerStatus extends GameStatus {
  cards: Card[];
  call: number | null;
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
  id: string;
  card: Card;
}

export interface PublicPlayer {
  call: number;
  cards: number;
  id: string;
  name: string;
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
      console.log("settin events");
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
  team: Team;
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

export const selectAvailableTeams = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => {
    const players = (playerState || gameState)?.players ?? [];
    const invalidTeams = Object.entries(groupBy(players, "team"))
      .map(([key, value]) => ({ count: value.length, team: key }))
      .filter(({ count }) => count === 2)
      .map(({ team }) => team as Team);
    return [Team.NorthSouth, Team.EastWest]
      .filter((team) => !invalidTeams.includes(team))
      .map((team) => ({
        label: team === Team.NorthSouth ? "North/South" : "East/West",
        value: team,
      }));
  }
);

export const selectPlayers = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) => playerState?.players || gameState?.players || []
);

export const selectPlayerCards = createSelector(
  getPlayerState,
  (player) => player?.cards || []
);

export const selectPlayerCardsRevealed = createSelector(
  getPlayerState,
  (player) => player?.revealed || false
);

export const selectCurrentPlayer = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState): PublicPlayer | undefined =>
    playerState?.players[playerState?.current_player] ||
    gameState?.players[gameState?.current_player]
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

export const selectError = createSelector(
  (state: RootState) => state.game,
  (state) => state.error
);

export const selectPlayersById = createSelector(
  getPlayerState,
  getGameState,
  (playerState, gameState) =>
    Object.fromEntries(
      Object.values(
        (playerState || gameState)?.players ?? {}
      ).map(({ id, name }) => [id, name])
    )
);

export const selectOrderedPlayers = createSelector(
  selectPlayers,
  selectUsername,
  (players, username) => {
    const after = takeWhile(players, (p) => p.name !== username);
    return dropWhile(players, (p) => p.name !== username).concat(after);
  }
);

export type TrickByPlayerId = { [playerId: string]: PlayedCard };

export const selectTrickByPlayerId = createSelector(
  selectTrick,
  (trick: PlayedCard[]): TrickByPlayerId =>
    trick.reduce((acc, obj) => ({ ...acc, [obj.id]: obj }), {})
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
      Object.values(
        (playerState || gameState)?.players ?? {}
      ).map(({ id, name }) => [id, name])
    )
);
