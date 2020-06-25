import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useMemo } from "react";

import { Card, playCard } from "./features/game/gameSlice";

import { PlayingCard } from "./Card"
import { HorizontalLayout, VerticalLayout } from "./Layout";

interface PlayerHandProps {
  cards: Card[];
}

export function PlayerHand({ cards }: PlayerHandProps) {
  const dispatch = useDispatch();
  const getOnClick = useCallback(
    (card: Card) => {
      return () => dispatch(playCard(card));
    },
    [dispatch]
  );
  return (
    <HorizontalLayout justifyContent="center" alignItems="center">
      {cards.map((card) => (
        <PlayingCard
          key={`${card.value}-${card.suit}`}
          card={card}
          onClick={getOnClick(card)}
          orientation="bottom"
        />
      ))}
    </HorizontalLayout>
  );
}

interface HiddenHandProps {
  cards: number;
  position: "top" | "side";
}

export function HiddenHand({ cards, position }: HiddenHandProps) {
  const Component = position === "top" ? HorizontalLayout : VerticalLayout;
  return (
    <Component justifyContent="center" alignItems="stretch">
      {Array.from(Array(cards)).map((_, i) => (
        <HiddenCard key={`${position}-${i}`} position={position} />
      ))}
    </Component>
  );
}

interface HiddenCardProps {
  position: "top" | "side";
}

export function HiddenCard({ position }: HiddenCardProps) {
  const style = useMemo((): React.CSSProperties => {
    return {
      fontSize: position === "top" ? "6em" : "2em",
      transform: position === "top" ? undefined : "rotate(90deg)",
    };
  }, [position]);
  return (
    <div style={style}>
      <span dangerouslySetInnerHTML={{ __html: "&#127136;" }} />
    </div>
  );
}
