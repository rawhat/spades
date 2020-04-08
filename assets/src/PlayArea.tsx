import React from 'react';
import { useSelector } from "react-redux";

import {
  State,
  selectCurrentPlayer,
  selectGameState,
  selectPlayerCardsRevealed,
  selectTrick
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import CallBox from "./CallBox";
import { cardValue } from "./Hand";

import viewStyle from "./PlayArea.module.css";

function PlayArea() {
  const username = useSelector(selectUsername);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const cardsRevealed = useSelector(selectPlayerCardsRevealed);
  const gameState = useSelector(selectGameState);
  const trick = useSelector(selectTrick);

  const isBidding = gameState === State.Bidding && currentPlayer?.name === username;

  return (
    <div className={viewStyle.container}>
      <div className={viewStyle.main}>
        {gameState === State.Waiting && <div>Waiting for players...</div>}
        {gameState === State.Bidding && <div>Make your bids!</div>}
        {gameState === State.Playing && (
          <div>
            <div>Current trick:</div>
            {trick.map(({name, card}) => (
              <div key={JSON.stringify(card)}>
                {name}: {cardValue(card.value)} {card.suit}
              </div>
            ))}
          </div>
        )}
      </div>
      <div className={viewStyle.playerCall}>
        {isBidding && <CallBox revealed={cardsRevealed} />}
      </div>
    </div>
  );
}

export default PlayArea;
