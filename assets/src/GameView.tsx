import React from "react";
import dropWhile from "lodash/dropWhile";
import takeWhile from "lodash/takeWhile";
import { useMemo } from "react";
import { useSelector } from "react-redux";

import { PlayerStatus } from "./features/game/gameSlice";
import { RootState } from "./app/store";
import { State } from "./features/game/gameSlice";

import { HiddenHand } from "./Hand";
import { PlayerHand } from "./Hand";

import viewStyle from "./GameView.module.css";

interface GameViewProps {
  state: PlayerStatus | undefined;
}

const style = (backgroundColor: string) => ({
  backgroundColor,
  width: '100%',
  height: '100%',
})

const GameView = ({ state }: GameViewProps) => {
  const username = useSelector((state: RootState) =>
    state.user.username
  );

  const [_self, leftPlayer, teammate, rightPlayer] = useMemo(() => {
    if (!state) {
      return [];
    }
    const after = takeWhile(state.players, p => p.name !== username);
    return dropWhile(state.players, p => p.name !== username).concat(after);
  }, [username, state]);

  if (!state) {
    return null;
  }

  return (
    <div className={viewStyle.container}>
      <div className={viewStyle.mainPanel}>
        <div className={viewStyle.leftHand}>
          {leftPlayer && (
            <>
              <HiddenHand cards={leftPlayer.cards} orientation="horizontal" />
              <div>{leftPlayer.name}</div>
            </>
          )}
        </div>
        <div className={viewStyle.middleSection}>
          <div className={viewStyle.topHand}>
            {teammate && (
              <>
                <div>{teammate.name}</div>
                <HiddenHand cards={teammate.cards} orientation="vertical" />
              </>
            )}
          </div>
          <div className={viewStyle.playArea}>
            {state.state === State.Waiting && <div>Waiting for players...</div>}
            {state.state === State.Bidding && <div>Make your bids!</div>}
          </div>
          <div className={viewStyle.playerHand}>
            <div style={style('lightgray')}>
              {state.cards && <PlayerHand cards={state.cards} />}
            </div>
          </div>
        </div>
        <div className={viewStyle.rightHand}>
          {rightPlayer && (
            <>
              <div>{rightPlayer.name}</div>
              <HiddenHand cards={rightPlayer.cards} orientation="horizontal" />
            </>
          )}
        </div>
      </div>
      <div className={viewStyle.sideBar}>
        <div style={style('lightblue')}>
          This will have chat.
        </div>
      </div>
    </div>
  )
};

export default GameView;
