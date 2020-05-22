import {
  configureStore,
  getDefaultMiddleware,
  ThunkAction,
  Action,
} from "@reduxjs/toolkit";

import { gameSocketMiddleware } from "../features/game/socket";

import rootReducer, { RootState } from "./rootReducer";

export const store = configureStore({
  middleware: [...getDefaultMiddleware(), gameSocketMiddleware],
  reducer: rootReducer,
});

if (process.env.NODE_ENV === "development" && (module as any).hot) {
  (module as any).hot.accept("./rootReducer", () => {
    const newRootReducer = require("./rootReducer").default;
    store.replaceReducer(newRootReducer);
  });
}

export type { RootState };

export type AppThunk = ThunkAction<void, RootState, unknown, Action<string>>;

//export type Store = typeof store;
