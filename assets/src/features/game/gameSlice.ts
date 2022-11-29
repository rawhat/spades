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
  id: number;
  call: number;
};

type StateChangedEvent = {
  type: "state_changed";
  old: GameState;
  new: GameState;
};

export type PlayedCardEvent = {
  type: "played_card";
  id: number;
  card: Card;
};

type HandEndedEvent = {
  type: "hand_ended";
};

type RoundEndedEvent = {
  type: "round_ended";
};

type AwardedTrickEvent = {
  type: "awarded_trick";
  winner: number;
};

type RevealedCardsEvent = {
  type: "revealed_cards";
  id: number;
};

type DealtCardsEvent = {
  type: "dealt_cards";
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
  created_by: string;
  current_player: string;
  id: string;
  last_trick: PlayedCard[];
  name: string;
  player_position: Record<Position, string>;
  players: PublicPlayer[];
  scores: Record<Team, number>;
  state: State;
  trick: PlayedCard[];
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
  Clubs = "C",
  Diamonds = "D",
  Hearts = "H",
  Spades = "S",
}

export interface Card {
  suit: Suit;
  value: string;
}

export interface PlayedCard {
  card: Card;
  id: number;
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

type GameResult =
  | { type: "game_state"; data: GameStatus }
  | { type: "player_state"; data: PlayerStatus };

export const loadGameState = (id: string) => async (dispatch: Dispatch) => {
  const result = await get<GameResult>(`/game/${id}`);
  if (result.type === "game_state") {
    dispatch(setGameState(result.data));
  } else {
    dispatch(setPlayerState(result.data));
  }
};

export const socketError = createAction<string>("game/socketError");

interface JoinGamePayload {
  id: number;
  position: Position;
  username: string;
}
export const joinGame = createAction<JoinGamePayload>("game/join");
export const observeGame = createAction<{ id: string; username?: string }>(
  "game/observe"
);
export const addBot = createAction<{ id: number; position: Position }>(
  "game/addBot"
);

export const revealCards = createAction<{ id: number }>("game/reveal");

type Call = {
  id: number;
  call: { count: number } | "blind_nil" | "nil";
};

export const makeCall = createAction<Call>("game/makeCall");

type PlayCard = {
  id: number;
  card: Card;
};

export const playCard = createAction<PlayCard>("game/playCard");

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

export type TrickByPlayerId = { [player: string]: PlayedCard };

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

export const selectIsCreator = createSelector(
  getPlayerState,
  getGameState,
  selectSelf,
  (playerState, gameState, self) => {
    const createdBy = playerState?.created_by || gameState?.created_by;
    if (createdBy) {
      return self?.name === createdBy;
    }
    return false;
  }
);
