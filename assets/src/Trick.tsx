import * as React from "react";
import { useEffect } from "react";
import { useSelector } from "react-redux";
import { useState } from "react";

import {
  Event,
  PlayedCard,
  isEvent,
  selectEvents,
  selectOrderedPlayers,
  selectTrickByPlayerId,
} from "./features/game/gameSlice";

import { HorizontalLayout, VerticalLayout } from "./Layout";
import { EmptyCard, PlayingCard } from "./Card";

function Trick() {
  const [bottom, left, top, right] = useSelector(selectOrderedPlayers);
  const trickByPlayerId = useSelector(selectTrickByPlayerId);
  const events = useSelector(selectEvents);
  const [displayedTrick, setDisplayedTrick] = useState(trickByPlayerId);

  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    // We only care about events that "require" some delay to be nice. These are
    // adding cards to the trick, or when the trick is complete.
    if (
      events.some(isEvent("played_card")) ||
      events.some(isEvent("awarded_trick"))
    ) {
      const performEvent = (event: Event) => {
        if (isEvent("played_card")(event)) {
          setDisplayedTrick((prev) => ({ ...prev, [event.id]: event }));
        } else {
          setDisplayedTrick({});
        }
      };
      const [nextEvent, ...nextEvents] = events;
      performEvent(nextEvent);
      let index = 0;
      interval = setInterval(() => {
        const nextEvent = nextEvents[index++];
        if (!nextEvent) {
          clearInterval(interval);
          return;
        }
        performEvent(nextEvent);
      }, 750);
    }

    return () => {
      clearInterval(interval);
    };
  }, [events, trickByPlayerId]);

  const bottomCard = bottom && displayedTrick[bottom.id];
  const leftCard = left && displayedTrick[left.id];
  const topCard = top && displayedTrick[top.id];
  const rightCard = right && displayedTrick[right.id];

  const winner =
    Object.keys(displayedTrick).length === 4 &&
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
