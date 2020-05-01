import { Dispatch } from "redux";
import { History } from "history";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { get, post } from "../../app/client";

interface LobbyState {
  games: GameResponse[];
}

const initialState: LobbyState = {
  games: [],
};

export const lobbySlice = createSlice({
  name: "lobby",
  initialState,
  reducers: {
    loadGames: (state: LobbyState, action: PayloadAction<GameResponse[]>) => {
      state.games = action.payload;
    },
    newGame: (state: LobbyState, action: PayloadAction<GameResponse>) => {
      state.games.push(action.payload);
    },
  },
});

export const { loadGames, newGame } = lobbySlice.actions;

type GameResponse = {
  id: string;
  name: string;
  players: number;
}

export const fetchGames = () => async (dispatch: Dispatch) => {
  const data = await get<{ games: GameResponse[] }>("/game/");
  dispatch(loadGames(data.games));
};

export const createGame = (name: string, history: History) => async (dispatch: Dispatch) => {
  const data = await post<GameResponse>("/game", { name });
  dispatch(newGame(data));
  history.push(`/game/${data.id}`);
};

export default lobbySlice.reducer;
