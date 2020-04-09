import groupBy from "lodash/groupBy";
import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createAction, createSlice, PayloadAction } from "@reduxjs/toolkit";

import { get } from "../../app/client";
import { RootState } from "../../app/store";

interface GameState {
  game?: GameStatus;
  playerState?: PlayerStatus;
}

export enum Team {
  One,
  Two
}

export interface GameStatus {
  id: string;
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

enum Suit {
  Clubs = "clubs",
  Diamonds = "diamonds",
  Hearts = "hearts",
  Spades = "spades",
}

export interface Card {
  suit: Suit;
  value: number;
}

interface PlayedCard {
  name: string
  card: Card
};

export interface PublicPlayer {
  call: number;
  cards: number;
  name: string,
  revealed: boolean;
  team: Team;
  tricks: number;
}

const initialState: GameState = {};

export const gameSlice = createSlice({
  name: "game",
  initialState,
  reducers: {
    setGameState: (state, action: PayloadAction<GameStatus>) => {
      state.game = action.payload;
    },
    setPlayerState: (state, action: PayloadAction<PlayerStatus>) => {
      state.playerState = action.payload;
    }
  },
});

export const { setGameState } = gameSlice.actions;

export const loadGameState = (id: string) => async (dispatch: Dispatch) => {
  const data = await get<{game: GameStatus}>(`/game/${id}`);
  dispatch(setGameState(data.game));
}

export const socketError = createAction<string>("game/socketError");

type JoinGamePayload = {id: string, team: Team, username: string};
export const joinGame = createAction<JoinGamePayload>("game/join");

export const revealCards = createAction("game/reveal");
export const makeCall = createAction<number>("game/makeCall");
export const playCard = createAction<Card>("game/playCard");

export const { setPlayerState } = gameSlice.actions;

export default gameSlice.reducer;

export const getGameState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.game
)

export const getPlayerState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.playerState
)

export const selectGameLoaded = createSelector(
  getGameState,
  (state: GameStatus | undefined) => !!state
)

export const selectAvailableTeams = createSelector(
  getGameState,
  gameState => {
    const invalidTeams =
      Object.entries(groupBy(gameState?.players || [], 'team'))
      .map(([key, value]) => ({count: value.length, team: key}))
      .filter(({count}) => count === 2)
      .map(({team}) => parseInt(team));
    return [0, 1].filter(team => !invalidTeams.includes(team));
  }
);

export const selectPlayers = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) =>
    playerState?.players || gameState?.players || []
)

export const selectPlayerCards = createSelector(
  getPlayerState,
  player => player?.cards || []
)

export const selectPlayerCardsRevealed = createSelector(
  getPlayerState,
  player => player?.revealed || false
)

export const selectCurrentPlayer = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState): PublicPlayer | undefined =>
    playerState?.players[playerState?.current_player] ||
      gameState?.players[gameState?.current_player]
)

export const selectGameState = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState): State | undefined =>
    playerState?.state || gameState?.state
)

export const selectTrick = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) =>
    playerState?.trick || gameState?.trick || []
)

export const selectScores = createSelector(
  getGameState,
  getPlayerState,
  (gameState, playerState) =>
    playerState?.scores || gameState?.scores || []
)
