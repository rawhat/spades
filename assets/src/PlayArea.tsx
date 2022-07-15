import * as React from "react";
import { useCallback } from "react";
import { useSelector } from "react-redux";

import {
  State,
  isEvent,
  selectEvents,
  selectGameState,
} from "./features/game/gameSlice";

import CallBox from "./CallBox";
import ScoreBox from "./ScoreBox";
import Trick from "./Trick";
import useDelay from "./useDelay";
import { VerticalLayout } from "./Layout";

function PlayArea() {
  const gameState = useSelector(selectGameState);
  const events = useSelector(selectEvents);

  const shouldDelay = useCallback(
    (previousState: State | undefined, currentState: State | undefined) => {
      return Boolean(
        previousState &&
        currentState &&
        previousState === State.Playing &&
        currentState === State.Bidding &&
        events.some(isEvent("played_card"))
      );
    },
    [events]
  );

  const state = useDelay(gameState, shouldDelay);

  return (
    <VerticalLayout flexGrow={1} height="100%" position="relative">
      <VerticalLayout
        flexGrow={1}
        alignItems="center"
        justifyContent="center"
        width="auto"
      >
        {state === State.Waiting && <div>Waiting for players...</div>}
        {state === State.Bidding && <div>Make your bids!</div>}
        {state === State.Playing && <Trick />}
      </VerticalLayout>
      <ScoreBox />
      {state === State.Bidding && <CallBox />}
    </VerticalLayout>
  );
}

export default PlayArea;
