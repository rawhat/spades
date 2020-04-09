import React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";

import { Card, playCard } from "./features/game/gameSlice";

import viewStyle from "./Hand.module.css";

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
    <div className={viewStyle.playerHand}>
      {cards.map((card) => (
        <PlayerCard
          key={`${card.value}-${card.suit}`}
          card={card}
          onClick={getOnClick(card)}
        />
      ))}
    </div>
  );
}

interface HiddenHandProps {
  cards: number;
  orientation: "vertical" | "horizontal";
}

export function HiddenHand({ cards, orientation }: HiddenHandProps) {
  return (
    <div className={viewStyle[`hiddenHand-${orientation}`]}>
      {Array.from(Array(cards)).map((_, i) => (
        <HiddenCard key={`${orientation}-${i}`} orientation={orientation} />
      ))}
    </div>
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

export function PlayerCard({ card, onClick }: PlayerCardProps) {
  return (
    <div className={viewStyle.playerCard} onClick={onClick}>
      <div>{cardValue(card.value)}</div>
      <div>{card.suit}</div>
    </div>
  );
}

interface HiddenCardProps {
  orientation: "horizontal" | "vertical";
}

export function HiddenCard({ orientation }: HiddenCardProps) {
  return <div className={viewStyle[`hiddenCard-${orientation}`]} />;
}
