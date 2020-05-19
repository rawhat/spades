import * as React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { Redirect } from "react-router-dom";
import { Route } from "react-router-dom";
import { Switch } from "react-router-dom";
import { useDispatch } from "react-redux";
import { useEffect } from "react";

import Authenticated from "./Authenticated";
import CreateAccount from "./CreateAccount";
import Game from "./Game";
import Lobby from "./Lobby";
import Login from "./Login";

import "spectre.css";
import "./App.css";

import TopNav from "./TopNav";
import { Divider, VerticalLayout } from "./Layout";
import { Progress, getRequest } from "./app/client";
import { useQuery } from "./useQuery";
import { setUsername } from "./features/user/userSlice";

const sessionCheck = getRequest("/session");

function App() {
  const dispatch = useDispatch();

  const { data, status } = useQuery<{ session: { username: string } }>(
    sessionCheck
  );

  useEffect(() => {
    if (data) {
      dispatch(setUsername(data.session.username));
    }
  }, [data, dispatch]);

  if (status === Progress.Loading) {
    return null;
  }

  return (
    <VerticalLayout height="100%">
      <Router>
        <TopNav />
        <Divider orientation="horizontal" />
        <Switch>
          <Route exact={true} path={["/", "/login"]}>
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
