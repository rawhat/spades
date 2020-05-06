import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { RootState } from "../../app/store";

import { post } from "../../app/client";

interface UserState {
  username?: string;
}

const initialState: UserState = {};

export const slice = createSlice({
  name: "user",
  initialState,
  reducers: {
    setUsername: (state, action: PayloadAction<string>) => {
      state.username = action.payload;
    },
  },
});

export const { setUsername } = slice.actions;

export default slice.reducer;

export const login = (username: string, password: string) =>
  async (dispatch: Dispatch) => {
    await post("/login", {username, password});
    dispatch(setUsername(username));
  }

export const createUser = (
  username: string,
  password: string,
  repeatedPassword: string
) => async (dispatch: Dispatch) => {
  await post<undefined>(
    "/user",
    {username, password, repeat_password: repeatedPassword}
  )
  dispatch(setUsername(username));
}

export const selectUserState = (state: RootState) => state.user;

export const selectUsername = createSelector(
  selectUserState,
  (state: UserState) => state.username
);
