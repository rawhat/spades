import React from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import { GameStatus } from "./features/game/gameSlice";
import { RootState } from "./app/store";
import { loadGameState } from "./features/game/gameSlice";

function Game() {
  const dispatch = useDispatch();
  const { id } = useParams();

  useEffect(() => {
    if (id) {
      dispatch(loadGameState(id));
    }
  }, [dispatch, id]);

  const state = useSelector((state: RootState) => state.game.game);

  return (
    <>
      <div>WELCOME TO THE GAME.</div>
      <GameInfo state={state} />
    </>
  );
}

interface GameInfoProps {
  state: GameStatus | undefined;
}

const GameInfo = ({ state }: GameInfoProps) => {
  if (!state) {
    return null;
  }

  // Who cares right now
  return <div>{JSON.stringify(state)}</div>;
};

export default Game;
