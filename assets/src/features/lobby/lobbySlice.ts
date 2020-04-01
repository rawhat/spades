import { Dispatch } from "redux";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { client } from "../../app/client";

interface LobbyState {
  games: string[],
}

const initialState: LobbyState = {
  games: []
}

export const lobbySlice = createSlice({
  name: 'lobby',
  initialState,
  reducers: {
    loadGames: (state, action: PayloadAction<string[]>) => {
      state.games = action.payload;
    }
  }
});

export const { loadGames } = lobbySlice.actions;

export const fetchGames = () => async (dispatch: Dispatch) => {
  const data = await client<{games: string[]}>("/game/");
  dispatch(loadGames(data.games));
}

export default lobbySlice.reducer;
