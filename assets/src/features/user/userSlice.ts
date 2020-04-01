import { createSlice, PayloadAction } from "@reduxjs/toolkit";

interface UserState {
  username?: string;
}

const initialState: UserState = {}

export const slice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    setUsername: (state, action: PayloadAction<string>) => {
      state.username = action.payload;
    }
  }
})

export const { setUsername } = slice.actions;

export default slice.reducer;
