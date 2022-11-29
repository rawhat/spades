import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useMemo } from "react";
import { useParams } from "react-router-dom";

import { Card, playCard } from "./features/game/gameSlice";

import { PlayingCard } from "./Card";
import { HorizontalLayout, VerticalLayout } from "./Layout";

interface PlayerHandProps {
  cards: Card[];
}

export function PlayerHand({ cards }: PlayerHandProps) {
  const dispatch = useDispatch();
  const { id } = useParams();
  const getOnClick = useCallback(
    (card: Card) => {
      return () => id && dispatch(playCard({ id: parseInt(id), card }));
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
        />
      ))}
    </HorizontalLayout>
  );
}

interface HiddenHandProps {
  cards: number;
  position: "top" | "left" | "right";
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
  position: "top" | "left" | "right";
}

export function HiddenCard({ position }: HiddenCardProps) {
  const style = useMemo((): React.CSSProperties => {
    let transform;
    if (position === "left") {
      transform = "rotate(90deg)";
    } else if (position === "right") {
      transform = "rotate(90deg)";
    }
    return {
      transform,
      maxWidth: "2vw",
      width: "auto",
    };
  }, [position]);
  return <img style={style} src="/static/images/BLUE_BACK.svg" />;
}
