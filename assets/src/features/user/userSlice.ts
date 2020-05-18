import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createAsyncThunk, createSlice, PayloadAction } from "@reduxjs/toolkit";

import { RootState } from "../../app/store";

import { Progress } from "../../app/client";
import { post } from "../../app/client";

interface UserState {
  error?: string;
  status: Progress;
  username?: string;
}

const initialState: UserState = {
  status: Progress.Idle,
};

export const slice = createSlice({
  name: "user",
  initialState,
  reducers: {
    setLoading: (state) => {
      state.status = Progress.Loading;
    },
    setError: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
      state.status = Progress.Error;
    },
    setUsername: (state, action: PayloadAction<string>) => {
      state.status = Progress.Loaded;
      state.username = action.payload;
    },
  },
});

export const { setLoading, setError, setUsername } = slice.actions;

export default slice.reducer;

interface LoginRequest {
  username: string;
  password: string;
}

export const login = createAsyncThunk(
  "user/login",
  async ({ username, password }: LoginRequest, { dispatch, signal }) => {
    dispatch(setLoading());
    try {
      const response = await post<{ data: string }>(
        "/session",
        { session: { username, password } },
        { signal }
      );
      dispatch(setUsername(response.data));
    } catch {
      dispatch(setError("Invalid username or password"));
    }
  }
);

export const createUser = (
  username: string,
  password: string,
  repeatedPassword: string
) => async (dispatch: Dispatch) => {
  await post<undefined>("/user", {
    user: {
      username,
      password,
      repeat_password: repeatedPassword,
    },
  });
  dispatch(setUsername(username));
};

export const selectUserState = (state: RootState) => state.user;

export const selectUsername = createSelector(
  selectUserState,
  (state: UserState) => state.username
);

export const selectLoginError = createSelector(
  selectUserState,
  (state: UserState) => state.error
);
