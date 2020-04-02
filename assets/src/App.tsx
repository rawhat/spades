import React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { Redirect } from "react-router-dom";
import { Route } from "react-router-dom";
import { Switch } from "react-router-dom";

import Authenticated from "./Authenticated";
import Game from "./Game";
import Home from "./Home";
import Lobby from "./Lobby";

import "./App.css";

function App() {
  return (
    <Router>
      <Switch>
        <Route exact={true} path="/">
          <Home />
        </Route>
        <Authenticated path="/lobby">
          <Lobby />
        </Authenticated>
        <Authenticated path="/game/:id">
          <Game />
        </Authenticated>
        <Route>
          <Redirect to="/" />
        </Route>
      </Switch>
    </Router>
  );
}

export default App;
