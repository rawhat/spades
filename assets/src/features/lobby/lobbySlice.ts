import { Dispatch } from "redux";
import { History } from "history";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { get, post } from "../../app/client";

interface LobbyState {
  games: string[];
}

const initialState: LobbyState = {
  games: [],
};

export const lobbySlice = createSlice({
  name: "lobby",
  initialState,
  reducers: {
    loadGames: (state, action: PayloadAction<string[]>) => {
      state.games = action.payload;
    },
    newGame: (state, action: PayloadAction<string>) => {
      state.games.push(action.payload);
    },
  },
});

export const { loadGames, newGame } = lobbySlice.actions;

export const fetchGames = () => async (dispatch: Dispatch) => {
  const data = await get<{ games: string[] }>("/game/");
  dispatch(loadGames(data.games));
};

export const createGame = (history: History) => async (dispatch: Dispatch) => {
  const data = await post<{ id: string }>("/game");
  dispatch(newGame(data.id));
  history.push(`/game/${data.id}`);
};

export default lobbySlice.reducer;
