import * as React from "react";
import * as ReactDOM from "react-dom";
import { createRoot } from "react-dom/client";
import "./index.css";
import { store } from "./app/store";
import { Provider } from "react-redux";
import App from "./App";

const root = createRoot(document.getElementById("root")!);

root.render(
  <React.StrictMode>
    <Provider store={store}>
      <App />
    </Provider>
  </React.StrictMode>
);
