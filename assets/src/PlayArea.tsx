import * as React from "react";
import { useSelector } from "react-redux";

import {
  State,
  selectGameState,
  selectOrderedPlayers,
  selectTrickByPlayerId,
} from "./features/game/gameSlice";

import CallBox from "./CallBox";
import ScoreBox from "./ScoreBox";
import { HorizontalLayout, VerticalLayout } from "./Layout";
import { EmptyCard, PlayingCard } from "./Card";

function PlayArea() {
  const gameState = useSelector(selectGameState);
  const trickById = useSelector(selectTrickByPlayerId);

  const [self, leftPlayer, topPlayer, rightPlayer] = useSelector(selectOrderedPlayers);

  const bottomCard = self && trickById[self.id];
  const leftCard = leftPlayer && trickById[leftPlayer.id];
  const topCard = topPlayer && trickById[topPlayer.id];
  const rightCard = rightPlayer && trickById[rightPlayer.id];

  return (
    <VerticalLayout flexGrow={1} height="100%" position="relative">
      <VerticalLayout flexGrow={1} alignItems="center" justifyContent="center" width="auto">
        {gameState === State.Waiting && <div>Waiting for players...</div>}
        {gameState === State.Bidding && <div>Make your bids!</div>}
        {gameState === State.Playing && (
          <HorizontalLayout alignItems="center">
            {leftCard && (
              <PlayingCard card={leftCard.card} />
            )}
            <VerticalLayout height="100%">
              {topCard ? (
                <PlayingCard card={topCard.card} />
              ) : (
                <EmptyCard />
              )}
              {bottomCard ? (
                <PlayingCard card={bottomCard.card} />
              ) : (
                <EmptyCard />
              )}
            </VerticalLayout>
            {rightCard && (
              <PlayingCard card={rightCard.card} />
            )}
          </HorizontalLayout>
        )}
      </VerticalLayout>
      <ScoreBox />
      {gameState === State.Bidding && <CallBox />}
    </VerticalLayout>
  );
}

export default PlayArea;
