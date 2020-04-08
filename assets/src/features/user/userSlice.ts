import { createSelector } from "reselect";
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

import { RootState } from "../../app/store";

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

export const selectUserState = (state: RootState) => state.user;

export const selectUsername = createSelector(
  selectUserState,
  (state: UserState) => state.username
);
