import React from "react";
import dropWhile from "lodash/dropWhile";
import takeWhile from "lodash/takeWhile";
import { useMemo } from "react";
import { useSelector } from "react-redux";

import { Card } from "./features/game/gameSlice";
import { PlayerStatus } from "./features/game/gameSlice";
import { RootState } from "./app/store";
import { State } from "./features/game/gameSlice";

import { HiddenHand } from "./Hand";
import { Marker } from "./Marker";
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

  const [self, leftPlayer, teammate, rightPlayer] = useMemo(() => {
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
            <Player
              cards={leftPlayer.cards}
              current={!!(state.players[0]?.name === leftPlayer.name)}
              name={leftPlayer.name}
              orientation="horizontal"
            />
          )}
        </div>
        <div className={viewStyle.middleSection}>
          <div className={viewStyle.topHand}>
            {teammate && (
              <Player
                cards={teammate.cards}
                current={!!(state.players[0]?.name === teammate.name)}
                name={teammate.name}
                orientation="vertical"
              />
            )}
          </div>
          <div className={viewStyle.playArea}>
            {state.state === State.Waiting && <div>Waiting for players...</div>}
            {state.state === State.Bidding && <div>Make your bids!</div>}
          </div>
          <div className={viewStyle.playerHand}>
            <div style={style('lightgray')}>
              {state.cards && (
                <Self
                  cards={state.cards}
                  current={!!(state.players[0]?.name === self.name)}
                  name={username || ""}
                  orientation="vertical"
                />
              )}
            </div>
          </div>
        </div>
        <div className={viewStyle.rightHand}>
          {rightPlayer && (
            <Player
              cards={rightPlayer.cards}
              current={!!(state.players[0]?.name === rightPlayer.name)}
              name={rightPlayer.name}
              orientation="horizontal"
            />
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

interface PlayerProps<T> {
  cards: T;
  name: string;
  current: boolean;
  orientation: "horizontal" | "vertical";
}

const Self = ({cards, current, name}: PlayerProps<Card[]>) => (
  <>
    <span>{name} {current && <Marker />}</span>
    <PlayerHand cards={cards} />
  </>
)

const Player = ({cards, current, name, orientation}: PlayerProps<number>) => (
  <>
    <HiddenHand cards={cards} orientation={orientation} />
    <span>{name} {current && <Marker />}</span>
  </>
)

export default GameView;
