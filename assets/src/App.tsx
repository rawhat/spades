import * as React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { Redirect } from "react-router-dom";
import { Route } from "react-router-dom";
import { Switch } from "react-router-dom";

import Authenticated from "./Authenticated";
import Game from "./Game";
import Home from "./Home";
import Lobby from "./Lobby";

import "spectre.css";
import "./App.css";

import TopNav from "./TopNav";
import { Divider, VerticalLayout } from "./Layout";

function App() {
  return (
    <VerticalLayout height="100%">
      <Router>
        <TopNav />
        <Divider orientation="horizontal" />
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
    </VerticalLayout>
  );
}

export default App;
