import React from "react";
import groupBy from "lodash/groupBy";
import isEqual from "lodash/isEqual";
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
  const [options, setOptions] = useState([0, 1]);

  useEffect(() => {
    if (state) {
      const countsByTeam = groupBy(state.players, 'team');
      const teams = [0, 1].filter(t =>
        countsByTeam[t] !== undefined
          ? countsByTeam[t].length < 2
          : true);
      if (!isEqual(teams, options)) {
        setTeam(teams[0]);
        setOptions(teams);
      }
    }
  }, [options, state])

  if (!state) {
    return null;
  }

  const onChange = (t: React.ChangeEvent<HTMLSelectElement>) => {
    setTeam(parseInt(t.currentTarget.value));
  }
  const teamOptions = (
    <select onChange={onChange}>
      {options.map(o => (
        <option value={o}>{o === 0 ? "One" : "Two"}</option>
      ))}
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
