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

  const shouldDelay = useCallback(
    (
      previousTrick: TrickByPlayerId | undefined,
      currentTrick: TrickByPlayerId | undefined
    ) => {
      return Boolean(
        previousTrick &&
          currentTrick &&
          size(previousTrick) === 3 &&
          size(currentTrick) === 0 &&
          events.some(isEvent("awarded_trick"))
      );
    },
    [events]
  );
  const addPlayedEvent = useCallback(
    (trick: TrickByPlayerId) => {
      const playedCardEvent = events.find(isEvent("played_card"));
      if (!playedCardEvent) {
        return trick;
      }
      return {
        ...trick,
        [playedCardEvent.id]: {
          player_id: playedCardEvent.id.toString(),
          card: playedCardEvent.card,
        },
      };
    },
    [events]
  );
  const trick = useDelay(trickByPlayerId, shouldDelay, addPlayedEvent) ?? {};

  const bottomCard = bottom && trick[bottom.id];
  const leftCard = left && trick[left.id];
  const topCard = top && trick[top.id];
  const rightCard = right && trick[right.id];

  const winner =
    Object.keys(trickByPlayerId).length === 4 &&
    events.find(isEvent("awarded_trick"))?.winner;

  return (
    <HorizontalLayout alignItems="center">
      <TrickCard layout="horizontal" playedCard={leftCard}>
        {winner && winner === leftCard?.id && <span>WINNER</span>}
        {leftCard && <PlayingCard card={leftCard.card} ratio={0.5} />}
      </TrickCard>
      <VerticalLayout height="100%">
        <TrickCard layout="vertical" playedCard={topCard}>
          {winner && winner === topCard?.id && <span>WINNER</span>}
          {topCard && <PlayingCard card={topCard.card} ratio={0.5} />}
        </TrickCard>
        <TrickCard layout="vertical" playedCard={bottomCard}>
          {bottomCard && <PlayingCard card={bottomCard.card} ratio={0.5} />}
          {winner && winner === bottomCard?.id && <span>WINNER</span>}
        </TrickCard>
      </VerticalLayout>
      <TrickCard layout="horizontal" playedCard={rightCard}>
        {rightCard && <PlayingCard card={rightCard.card} ratio={0.5} />}
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
