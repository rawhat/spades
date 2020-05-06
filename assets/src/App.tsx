import * as React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { Redirect } from "react-router-dom";
import { Route } from "react-router-dom";
import { Switch } from "react-router-dom";

import Authenticated from "./Authenticated";
import CreateAccount from "./CreateAccount";
import Game from "./Game";
import Lobby from "./Lobby";
import Login from "./Login";

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
          <Route path={["/", "/login"]}>
            <Login />
          </Route>
          <Route path="/create_user">
            <CreateAccount />
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
