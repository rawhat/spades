import React from "react";
import dropWhile from "lodash/dropWhile";
import takeWhile from "lodash/takeWhile";
import { useMemo } from "react";
import { useSelector } from "react-redux";

import {
  Card,
  selectCurrentPlayer,
  selectPlayers,
  selectPlayerCards,
  selectPlayerCardsRevealed,
  selectScores,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import PlayArea from "./PlayArea";
import { HiddenHand } from "./Hand";
import { Marker } from "./Marker";
import { PlayerHand } from "./Hand";

import viewStyle from "./GameView.module.css";

const style = (backgroundColor: string) => ({
  backgroundColor,
})

const GameView = () => {
  const username = useSelector(selectUsername);
  const players = useSelector(selectPlayers);
  const playerCards = useSelector(selectPlayerCards);
  const playerCardsRevealed = useSelector(selectPlayerCardsRevealed);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const scores = useSelector(selectScores);

  const [self, leftPlayer, teammate, rightPlayer] = useMemo(() => {
    const after = takeWhile(players, p => p.name !== username);
    return dropWhile(players, p => p.name !== username).concat(after);
  }, [username, players]);

  return (
    <div className={viewStyle.container}>
      <div className={viewStyle.mainPanel}>
        <div className={viewStyle.leftHand}>
          {leftPlayer && (
            <Player
              call={leftPlayer?.call}
              cards={leftPlayer.cards}
              current={currentPlayer?.name === leftPlayer?.name}
              name={leftPlayer.name}
              orientation="horizontal"
              tricks={leftPlayer?.tricks}
            />
          )}
        </div>
        <div className={viewStyle.middleSection}>
          <div className={viewStyle.topHand}>
            {teammate && (
              <Player
                call={teammate?.call}
                cards={teammate.cards}
                current={currentPlayer?.name === teammate?.name}
                name={teammate.name}
                orientation="vertical"
                tricks={teammate?.tricks}
              />
            )}
          </div>
          <div className={viewStyle.playArea}>
            <PlayArea />
          </div>
          <div className={viewStyle.playerHand}>
            <div style={style('lightgray')}>
              {playerCards && (
                <Self
                  call={self?.call}
                  cards={playerCards}
                  current={currentPlayer?.name === self?.name}
                  name={username || ""}
                  orientation="vertical"
                  revealed={playerCardsRevealed}
                  tricks={self?.tricks}
                />
              )}
            </div>
          </div>
        </div>
        <div className={viewStyle.rightHand}>
          {rightPlayer && (
            <Player
              call={rightPlayer?.call}
              cards={rightPlayer.cards}
              current={currentPlayer?.name === rightPlayer?.name}
              name={rightPlayer.name}
              orientation="horizontal"
              tricks={rightPlayer?.tricks}
            />
          )}
        </div>
      </div>
      <div className={viewStyle.sideBar}>
        <div style={style('lightblue')}>
          This will have chat.
        </div>
        <div>{JSON.stringify(scores)}</div>
      </div>
    </div>
  )
};

interface PlayerProps<T> {
  call?: number;
  cards: T;
  name: string;
  current: boolean;
  orientation: "horizontal" | "vertical";
  tricks?: number;
}

interface SelfProps extends PlayerProps<Card[]> {
  revealed: boolean;
}

const Self = ({call, cards, current, name, tricks}: SelfProps) => (
  <>
    <div className={viewStyle['statusBar-vertical']}>
      <span>{name} {current && <Marker />}</span>
      {call !== null && (
        <span>Call: {call} {tricks !== undefined && <span>({tricks})</span>}</span>
      )}
    </div>
    <PlayerHand cards={cards} />
  </>
)

const Player = ({call, cards, current, name, orientation, tricks}: PlayerProps<number>) => (
  <>
    <HiddenHand cards={cards} orientation={orientation} />
    <div className={viewStyle[`statusBar-${orientation}`]}>
      <span>{name} {current && <Marker />}</span>
      {call !== null && (
        <span>Call: {call} {tricks !== undefined && <span>({tricks})</span>}</span>
      )}
    </div>
  </>
)

export default GameView;
