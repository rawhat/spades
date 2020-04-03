import React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useState } from "react";

import { RootState } from "./app/store";
import {
  GameStatus,
  loadGameState,
} from "./features/game/gameSlice";

import GameView from "./GameView";
import { useGameState } from "./Socket";

function Game() {
  const dispatch = useDispatch();
  const { id } = useParams();
  const username = useSelector((state: RootState) =>
    state.user.username
  );

  useEffect(() => {
    if (id) {
      dispatch(loadGameState(id));
    }
  }, [dispatch, id]);

  const { state, joinGame } = useGameState(id, username);

  const onJoin = useCallback((team: number) => {
    if (id && username) {
      joinGame(team);
    }
  }, [id, joinGame, username])

  return (
    <>
      <span>
        <JoinButton onJoin={onJoin} state={state} />
        as {username}
      </span>
      <GameView state={state} />
    </>
  );
}

interface JoinButtonProps {
  onJoin: (team: number) => void;
  state: GameStatus | undefined;
}

const JoinButton = ({onJoin, state}: JoinButtonProps) => {
  const [team, setTeam] = useState<number | null>(0);
  if (!state) {
    return null;
  }

  const onChange = (t: React.ChangeEvent<HTMLSelectElement>) => {
    setTeam(parseInt(t.currentTarget.value));
  }
  const teamOptions = (
    <select onChange={onChange}>
      <option value={0}>One</option>
      <option value={1}>Two</option>
    </select>
  )

  const onClick = () => {
    if (team !== null) {
      onJoin(team);
    }
  }

  return (
    <span>
      {teamOptions}
      <button onClick={onClick}>Join Game</button>
    </span>
  );
}

export default Game;
