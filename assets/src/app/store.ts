import { configureStore, ThunkAction, Action } from "@reduxjs/toolkit";

import rootReducer, { RootState } from "./rootReducer";

export const store = configureStore({
  reducer: rootReducer
})

if (process.env.NODE_ENV === 'development' && (module as any).hot) {
  (module as any).hot.accept("./rootReducer", () => {
    const newRootReducer = require('./rootReducer').default;
    store.replaceReducer(newRootReducer);
  })
}

export type { RootState };

export type AppThunk = ThunkAction<void, RootState, unknown, Action<string>>;
