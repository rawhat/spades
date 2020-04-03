import React from 'react';

import { Card } from "./features/game/gameSlice";

import viewStyle from "./Hand.module.css";

interface PlayerHandProps {
  cards: Card[];
}

export function PlayerHand({cards}: PlayerHandProps) {
  return (
    <div className={viewStyle.playerHand}>
      {cards.map(card => (
        <PlayerCard key={`${card.value}-${card.suit}`} card={card} />
      ))}
    </div>
  )
}

interface HiddenHandProps {
  cards: number;
  orientation: "vertical" | "horizontal";
}

export function HiddenHand({cards, orientation}: HiddenHandProps) {
  return (
    <div className={viewStyle[`hiddenHand-${orientation}`]}>
      {Array.from(Array(cards)).map((_, i) => (
        <HiddenCard key={`${orientation}-${i}`} orientation={orientation} />
      ))}
    </div>
  )
}

interface PlayerCardProps {
  card: Card;
}

export function PlayerCard({card}: PlayerCardProps) {
  return (
    <div className={viewStyle.playerCard}>
      <div>{card.value}</div>
      <div>{card.suit}</div>
    </div>
  )
}

interface HiddenCardProps {
  orientation: "horizontal" | "vertical";
}

export function HiddenCard({orientation}: HiddenCardProps) {
  return (
    <div className={viewStyle[`hiddenCard-${orientation}`]} />
  )
}
