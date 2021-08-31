import * as React from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import { loadGameState, observeGame } from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import GameView from "./GameView";

function Game() {
  const dispatch = useDispatch();
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
