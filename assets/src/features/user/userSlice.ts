import { Dispatch } from "redux";
import { createSelector } from "reselect";
import { createAsyncThunk, createSlice, PayloadAction } from "@reduxjs/toolkit";

import { Progress } from "../../app/client";
import { RootState } from "../../app/store";
import { post } from "../../app/client";

interface UserState {
  error?: string;
  status: Progress;
  username?: string;
}

interface Session {
  id: number;
  username: string;
}

const initialState: UserState = {
  status: Progress.Idle,
};

export const login = createAsyncThunk<
  string,
  LoginRequest,
  {
    rejectValue: string;
  }
>(
  "user/login",
  async ({ username, password }: LoginRequest, { rejectWithValue, signal }) => {
    try {
      const response = await post<{ session: Session}>(
        "/session",
        { session: { username, password } },
        { signal }
      );
      return response.session.username;
    } catch {
      return rejectWithValue("Invalid username or password");
    }
  }
);

export const slice = createSlice({
  name: "user",
  initialState,
  reducers: {
    setError: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
    },
    setUsername: (state, action: PayloadAction<string | undefined>) => {
      state.username = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(login.pending, (state) => {
      state.status = Progress.Loading;
    });
    builder.addCase(login.fulfilled, (state, action) => {
      state.status = Progress.Loaded;
      state.username = action.payload;
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = Progress.Error;
      state.error = action.payload;
    });
  },
});

export const { setError, setUsername } = slice.actions;

export default slice.reducer;

interface LoginRequest {
  username: string;
  password: string;
}

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
