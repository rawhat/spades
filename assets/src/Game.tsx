import * as React from "react";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import { loadGameState, observeGame } from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import { useAppDispatch } from "./app/store";

import GameView from "./GameView";

function Game() {
  const dispatch = useAppDispatch();
  const { id } = useParams<{ id: string }>();

  const username = useSelector(selectUsername);

  useEffect(() => {
    if (id) {
      dispatch(loadGameState(id));
      dispatch(observeGame({ id, username }));
    }
  }, [dispatch, id, username]);

  return <GameView />;
}

export default Game;
