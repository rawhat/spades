import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useState } from "react";

import {
  Team,
  joinGame,
  loadGameState,
  selectAvailableTeams,
  selectConnected,
  selectGameLoaded,
  selectSelf,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import GameView from "./GameView";
import { Column, HorizontalLayout, VerticalLayout } from "./Layout";
import { Select } from "./Form";
import { Button } from "./Button";

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

  const onJoin = useCallback(
    (team: Team) => {
      if (id && username) {
        dispatch(joinGame({ id, team, username }));
      }
    },
    [dispatch, id, username]
  );

  useEffect(() => {
    if (self && !connected && id && username) {
      dispatch(joinGame({ id, team: self.team, username }));
    }
  }, [connected, dispatch, id, self, username]);

  return (
    <VerticalLayout flexGrow={1}>
      {!connected && gameLoaded && availableTeams.length > 0 && (
        <JoinButton onJoin={onJoin} />
      )}
      <GameView />
    </VerticalLayout>
  );
}

interface JoinButtonProps {
  onJoin: (team: Team) => void;
}

const JoinButton = ({ onJoin }: JoinButtonProps) => {
  const availableTeams = useSelector(selectAvailableTeams);
  const [team, setTeam] = useState<Team>(availableTeams[0]?.value);

  useEffect(() => {
    setTeam(availableTeams[0]?.value);
  }, [availableTeams]);

  const onChange = (value: string) => {
    setTeam(value as Team);
  };

  const onClick = () => {
    if (team !== null) {
      onJoin(team);
    }
  };

  return (
    <HorizontalLayout justifyContent="center">
      <Column width={1}>
        <Select onChange={onChange} options={availableTeams} />
      </Column>
      <Column width={2}>
        <Button onClick={onClick}>Join Game</Button>
      </Column>
    </HorizontalLayout>
  );
};

export default Game;
