import { combineReducers } from "@reduxjs/toolkit";
import gameReducer from "../features/game/gameSlice";
import userReducer from "../features/user/userSlice";

const rootReducer = combineReducers({
  game: gameReducer,
  user: userReducer,
});

export type RootState = ReturnType<typeof rootReducer>;

export default rootReducer;
