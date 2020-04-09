import React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useState } from "react";

import {
  joinGame,
  loadGameState,
  selectAvailableTeams,
  selectConnected,
  selectGameLoaded,
  selectSelf,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import GameView from "./GameView";

function Game() {
  const dispatch = useDispatch();
  const { id } = useParams();

  const availableTeams = useSelector(selectAvailableTeams);
  const connected = useSelector(selectConnected);
  const gameLoaded = useSelector(selectGameLoaded);
  const self = useSelector(selectSelf);
  const username = useSelector(selectUsername);

  useEffect(() => {
    if (id) {
      dispatch(loadGameState(id));
    }
  }, [dispatch, id]);

  const onJoin = useCallback((team: number) => {
    if (id && username) {
      dispatch(joinGame({id, team, username}));
    }
  }, [dispatch, id, username])

  useEffect(() => {
    if (self && !connected && id && username) {
      dispatch(joinGame({id, team: self.team, username}))
    }
  }, [connected, dispatch, id, self, username]);

  return (
    <>
      <span>
        {!connected &&  gameLoaded && availableTeams.length > 0 && (
          <>
            <JoinButton onJoin={onJoin} />
            as
            {' '}
          </>
        )}{username}
      </span>
      <GameView />
    </>
  );
}

interface JoinButtonProps {
  onJoin: (team: number) => void;
}

const JoinButton = ({onJoin}: JoinButtonProps) => {
  const availableTeams = useSelector(selectAvailableTeams);
  const [team, setTeam] = useState<number>(availableTeams[0]);

  useEffect(() => {
    setTeam(availableTeams[0]);
  }, [availableTeams])

  const onChange = (t: React.ChangeEvent<HTMLSelectElement>) => {
    setTeam(parseInt(t.currentTarget.value));
  }

  const onClick = () => {
    if (team !== null) {
      onJoin(team);
    }
  }

  return (
    <span>
      <select onChange={onChange}>
        {availableTeams.map(team => (
          <option key={team} value={team}>{team + 1}</option>
        ))}
      </select>
      <button onClick={onClick}>Join Game</button>
    </span>
  );
}

export default Game;
