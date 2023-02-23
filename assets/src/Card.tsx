import * as React from "react";
import { useMemo } from "react";

import { Card, Suit } from "./features/game/gameSlice";

export function cardToString(card: Card): string {
  return `${card.value} of ${card.suit}`;
}

interface PlayerCardProps {
  card: Card;
  onClick?: () => void;
  ratio?: number;
}

export function PlayingCard({ card, onClick, ratio = 4 }: PlayerCardProps) {
  const style = useMemo(() => {
    return {
      cursor: onClick && "pointer",
      maxWidth: `${ratio}vw`,
      height: "auto",
    };
  }, [onClick]);
  return (
    <img
      style={style}
      onClick={onClick}
      src={`/images/${card.value}${card.suit}.svg`}
    />
  );
}

export function EmptyCard() {
  return (
    <div style={{ opacity: 0 }}>
      <PlayingCard card={{ suit: Suit.Hearts, value: "2" }} />
    </div>
  );
}
