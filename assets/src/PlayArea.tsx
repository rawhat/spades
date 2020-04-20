import * as React from "react";
import { useSelector } from "react-redux";

import {
  State,
  selectCurrentPlayer,
  selectGameState,
  selectPlayerCardsRevealed,
  selectTrick,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import CallBox from "./CallBox";
import ScoreBox from "./ScoreBox";
import { VerticalLayout } from "./Layout";
import { cardValue } from "./Hand";

function PlayArea() {
  const username = useSelector(selectUsername);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const cardsRevealed = useSelector(selectPlayerCardsRevealed);
  const gameState = useSelector(selectGameState);
  const trick = useSelector(selectTrick);

  const isBidding =
    gameState === State.Bidding && currentPlayer?.name === username;

  return (
    <VerticalLayout flexGrow={1} height="100%" position="relative">
      <VerticalLayout flexGrow={1} alignItems="center" justifyContent="center">
        {gameState === State.Waiting && <div>Waiting for players...</div>}
        {gameState === State.Bidding && <div>Make your bids!</div>}
        {gameState === State.Playing && (
          <div>
            <div>Current trick:</div>
            {trick.map(({ name, card }) => (
              <div key={JSON.stringify(card)}>
                {name}: {cardValue(card.value)} {card.suit}
              </div>
            ))}
          </div>
        )}
      </VerticalLayout>
      <ScoreBox />
      {isBidding && <CallBox revealed={cardsRevealed} />}
    </VerticalLayout>
  );
}

export default PlayArea;
