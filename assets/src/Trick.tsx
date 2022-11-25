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

import useDelay from "./useDelay";
import { HorizontalLayout, VerticalLayout } from "./Layout";
import { EmptyCard, PlayingCard } from "./Card";

function Trick() {
  const [bottom, left, top, right] = useSelector(selectOrderedPlayers);

  const trickById = useSelector(selectTrickByPlayerId);
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
    (trick: TrickByPlayerId): TrickByPlayerId => {
      const playedCardEvent = events.find(isEvent("played_card"));
      if (!playedCardEvent) {
        return trick;
      }
      return {
        ...trick,
        [playedCardEvent.data.player]: {
          player: playedCardEvent.data.player,
          card: playedCardEvent.data.card,
        },
      };
    },
    [events]
  );
  const trick = useDelay(trickById, shouldDelay, addPlayedEvent) ?? {};

  const bottomCard = bottom && trick[bottom.id];
  const leftCard = left && trick[left.id];
  const topCard = top && trick[top.id];
  const rightCard = right && trick[right.id];

  const winner =
    Object.keys(trick).length === 4 &&
    events.find(isEvent("awarded_trick"))?.data.winner;

  return (
    <HorizontalLayout alignItems="center">
      <TrickCard layout="horizontal" playedCard={leftCard}>
        {winner && winner === leftCard?.player && <span>WINNER</span>}
        {leftCard && <PlayingCard card={leftCard.card} />}
      </TrickCard>
      <VerticalLayout height="100%">
        <TrickCard layout="vertical" playedCard={topCard}>
          {winner && winner === topCard?.player && <span>WINNER</span>}
          {topCard && <PlayingCard card={topCard.card} />}
        </TrickCard>
        <TrickCard layout="vertical" playedCard={bottomCard}>
          {bottomCard && <PlayingCard card={bottomCard.card} />}
          {winner && winner === bottomCard?.player && <span>WINNER</span>}
        </TrickCard>
      </VerticalLayout>
      <TrickCard layout="horizontal" playedCard={rightCard}>
        {rightCard && <PlayingCard card={rightCard.card} />}
        {winner && winner === rightCard?.player && <span>WINNER</span>}
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
