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
  PlayerStatus,
  joinGame,
  loadGameState,
  loadPlayerState,
  selectExistingTeamCounts,
  selectGameState,
  selectPlayerState
} from "./features/game/gameSlice";

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

  const gameState = useSelector(selectGameState);
  const playerState = useSelector(selectPlayerState);

  const canJoin =
    gameState &&
    gameState.players.length < 4 &&
    !gameState.players.find(({name}) => name !== username);

  const shouldLoadPlayerState =
    gameState &&
    !playerState &&
    gameState.players.find(({name}) => name === username);

  useEffect(() => {
    if (shouldLoadPlayerState && username && id) {
      dispatch(loadPlayerState(username, id));
    }
  }, [dispatch, id, username, shouldLoadPlayerState])

  const onJoin = useCallback((team: number) => {
    if (id && username) {
      dispatch(joinGame(id, username, team));
    }
  }, [dispatch, id, username])

  const { state } = useGameState(id, username);

  return (
    <>
      <div>WELCOME TO THE GAME.</div>
      {canJoin && <JoinButton onJoin={onJoin} state={gameState} />}
      <GameInfo state={state} />
      {/*<PlayerInfo state={playerState} />*/}
    </>
  );
}

interface JoinButtonProps {
  onJoin: (team: number) => void;
  state: GameStatus | undefined;
}

const JoinButton = ({onJoin, state}: JoinButtonProps) => {
  const counts = useSelector(selectExistingTeamCounts);
  const options = Object.entries(counts)
    .filter(([_0, count]) => count < 2);
  const initialTeam = options.length > 0 ? parseInt(options[0][0]) : null;
  const [team, setTeam] = useState<number | null>(initialTeam);
  if (!state) {
    return null;
  }

  let teamOptions: JSX.Element | undefined;
  if (options.length > 0) {
    const onChange = (t: React.ChangeEvent<HTMLSelectElement>) =>
      setTeam(parseInt(t.currentTarget.value));
    teamOptions = (
      <select onChange={onChange}>
        {options.map(([t, count]) =>
          count === 2 ? null : <option key={t} value={t}>{t}</option>
        )}
      </select>
    )
  }

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

interface PlayerInfoProps {
  state: PlayerStatus | undefined;
}

const PlayerInfo = ({ state }: PlayerInfoProps) => {
  if (!state) {
    return null;
  }

  // Who cares right now
  return <div>{JSON.stringify(state)}</div>;
}

export default Game;
