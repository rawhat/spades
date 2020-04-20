import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useMemo } from "react";

import { Card, playCard } from "./features/game/gameSlice";

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
    <HorizontalLayout>
      {cards.map((card) => (
        <PlayerCard
          key={`${card.value}-${card.suit}`}
          card={card}
          onClick={getOnClick(card)}
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
    <Component justifyContent="space-between" alignItems="stretch">
      {Array.from(Array(cards)).map((_, i) => (
        <HiddenCard key={`${position}-${i}`} position={position} />
      ))}
    </Component>
  );
}

export function cardValue(value: number): string {
  switch (value) {
    case 1:
      return "A";
    case 11:
      return "J";
    case 12:
      return "Q";
    case 13:
      return "K";
    default:
      return value.toString();
  }
}

interface PlayerCardProps {
  card: Card;
  onClick: () => void;
}

const playerCardStyle = {
  height: 80,
  width: 60,
  borderRadius: 2,
  border: "1px solid lightgray",
};

export function PlayerCard({ card, onClick }: PlayerCardProps) {
  return (
    <div onClick={onClick} style={playerCardStyle}>
      <VerticalLayout>
        <div>{cardValue(card.value)}</div>
        <div>{card.suit}</div>
      </VerticalLayout>
    </div>
  );
}

interface HiddenCardProps {
  position: "top" | "side";
}

export function HiddenCard({ position }: HiddenCardProps) {
  const style = useMemo(() => {
    const baseStyle = {
      borderRadius: 2,
      border: "1px solid lightgray",
      backgroundColor: "darkblue",
    };
    if (position === "top") {
      return {
        ...baseStyle,
        height: 80,
        width: 60,
      };
    }
    return {
      ...baseStyle,
      height: 60,
      width: 80,
    };
  }, [position]);
  return <div style={style} />;
}
