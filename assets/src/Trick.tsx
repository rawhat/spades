import * as React from "react";
import size from "lodash/size";
import { useCallback } from "react";
import { useSelector } from "react-redux";

import {
  PlayedCard,
  TrickByPlayerId,
  isEvent,
  selectEvents,
  selectOrderedPlayers,
  selectTrickByPlayerId,
} from "./features/game/gameSlice";

import { HorizontalLayout, VerticalLayout } from "./Layout";
import { EmptyCard, PlayingCard } from "./Card";
import useDelay from "./useDelay";

function Trick() {
  const [bottom, left, top, right] = useSelector(selectOrderedPlayers);
  const trickByPlayerId = useSelector(selectTrickByPlayerId);
  const events = useSelector(selectEvents);

  const bottomCard = bottom && trickByPlayerId[bottom.id];
  const leftCard = left && trickByPlayerId[left.id];
  const topCard = top && trickByPlayerId[top.id];
  const rightCard = right && trickByPlayerId[right.id];

  const winner =
    Object.keys(trickByPlayerId).length === 4 &&
    events.find(isEvent("awarded_trick"))?.winner;

  return (
    <HorizontalLayout alignItems="center" width="100%" height="100%">
      <TrickCard layout="horizontal" playedCard={leftCard}>
        {winner && winner === leftCard?.id && <span>WINNER</span>}
        {leftCard && <PlayingCard card={leftCard.card} />}
      </TrickCard>
      <VerticalLayout
        height="80%"
        alignItems="center"
        justifyContent="space-between"
      >
        <TrickCard layout="vertical" playedCard={topCard}>
          {winner && winner === topCard?.id && <span>WINNER</span>}
          {topCard && <PlayingCard card={topCard.card} />}
        </TrickCard>
        <TrickCard layout="vertical" playedCard={bottomCard}>
          {bottomCard && <PlayingCard card={bottomCard.card} />}
          {winner && winner === bottomCard?.id && <span>WINNER</span>}
        </TrickCard>
      </VerticalLayout>
      <TrickCard layout="horizontal" playedCard={rightCard}>
        {rightCard && <PlayingCard card={rightCard.card} />}
        {winner && winner === rightCard?.id && <span>WINNER</span>}
      </TrickCard>
    </HorizontalLayout>
  );
}

export default Trick;

interface TrickCardProps {
  children: React.ReactNode;
  layout: "horizontal" | "vertical";
  playedCard?: PlayedCard;
}

export function TrickCard({ children, playedCard, layout }: TrickCardProps) {
  if (!playedCard) {
    return <EmptyCard />;
  }

  if (layout === "horizontal") {
    return <HorizontalLayout alignItems="center">{children}</HorizontalLayout>;
  }

  return <VerticalLayout justifyContent="center">{children}</VerticalLayout>;
}
