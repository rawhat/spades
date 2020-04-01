import { Dispatch } from "redux";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { client } from "../../app/client";

interface GameState {
  game?: GameStatus;
  playerState?: PlayerStatus;
}

interface PlayerStatus {
}

enum State {
  Waiting = "waiting",
  Bidding = "bidding",
  Playing = "playing"
}

enum Suit {
  Clubs = "clubs",
  Diamonds = "diamonds",
  Hearts = "hearts",
  Spades = "spades"
}

interface Card {
  suit: Suit;
  value: number;
}

type PlayedCard = [string, Card];

export interface GameStatus {
  id: string;
  cards: number;
  scores: {[team: number]: number};
  current_player: number;
  play_order: string[];
  spades_broken: boolean;
  state: State,
  trick: PlayedCard[];
}

const initialState: GameState = {};

export const gameSlice = createSlice({
  name: 'game',
  initialState,
  reducers: {
    getState: (state, action: PayloadAction<GameStatus>) => {
      state.game = action.payload;
    }
  }
});

export const { getState } = gameSlice.actions;

export const loadGameState = (id: string) => async (dispatch: Dispatch) => {
  const data = await client<{game: GameStatus}>(`/game/${id}`);
  dispatch(getState(data.game));
}

export default gameSlice.reducer;
