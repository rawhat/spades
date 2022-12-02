import { useSelector } from "react-redux";

import { State, selectGameState } from "./features/game/gameSlice";

import CallBox from "./CallBox";
import ScoreBox from "./ScoreBox";
import Trick from "./Trick";
import { VerticalLayout } from "./Layout";

function PlayArea() {
  const state = useSelector(selectGameState);

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
