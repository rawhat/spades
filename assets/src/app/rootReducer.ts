import { combineReducers } from "@reduxjs/toolkit";
import gameReducer from "../features/game/gameSlice";
import lobbyReducer from "../features/lobby/lobbySlice";
import userReducer from "../features/user/userSlice";

const rootReducer = combineReducers({
  game: gameReducer,
  lobby: lobbyReducer,
  user: userReducer,
});

export type RootState = ReturnType<typeof rootReducer>;

export default rootReducer;
