import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { get, post } from "../../app/client";
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
  current_player: number;
  players: PublicPlayer[];
  spades_broken: boolean;
  state: State;
  trick: PlayedCard[];
}

export interface PlayerStatus extends GameStatus {
  cards: Card[],
  call: number | null;
  tricks: number | null;
  spades_broken: boolean;
  state: State;
  trick: PlayedCard[];
}

enum State {
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

interface Card {
  suit: Suit;
  value: number;
}

type PlayedCard = [string, Card];

interface PublicPlayer {
  name: string | null,
  cards: number;
  call: number;
  tricks: number;
  team: Team;
}

const initialState: GameState = {};

export const gameSlice = createSlice({
  name: "game",
  initialState,
  reducers: {
    getState: (state, action: PayloadAction<GameStatus>) => {
      state.game = action.payload;
    },
    getPlayerState: (state, action: PayloadAction<PlayerStatus>) => {
      state.playerState = action.payload;
    }
  },
});

export const { getPlayerState, getState } = gameSlice.actions;

export const loadGameState = (id: string) => async (dispatch: Dispatch) => {
  const data = await get<{ game: GameStatus }>(`/game/${id}`);
  dispatch(getState(data.game));
};

export const loadPlayerState = (name: string, id: string) => async (dispatch: Dispatch) => {
  const data = await get<{game: PlayerStatus}>(`/game/${id}/player/${name}`);
  dispatch(getPlayerState(data.game));
}

export const joinGame = (id: string, name: string, team: number) => async (dispatch: Dispatch) => {
  const data = await post<{game: PlayerStatus}>(`/game/${id}/player`, {name, team});
  dispatch(getPlayerState(data.game));
}

export default gameSlice.reducer;

export const selectGameState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.game
)

export const selectPlayerState = createSelector(
  (state: RootState) => state.game,
  (game: GameState) => game.playerState
)

type TeamCount = {[Team.One]: number, [Team.Two]: number};

export const selectExistingTeamCounts = createSelector(
  selectGameState,
  (game: GameStatus | undefined): TeamCount =>
    !game
    ? {0: 0, 1: 0}
    : game.players.reduce((counts, player) => ({
        ...counts,
        [player.team]: (counts[player.team] ?? 0) + 1
      }), {0: 0, 1: 1} as TeamCount)
)
