import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useMemo } from "react";

import { Card, Suit, playCard } from "./features/game/gameSlice";

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
    <HorizontalLayout justifyContent='space-between' alignItems='center'>
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

const initialCode = 127137;
function getCardCode(offset: number) {
  return `&#${initialCode + offset};`;
}

function suitToOffset(suit: Suit): number {
  switch(suit) {
    case Suit.Spades: {
      return 0;
    }
    case Suit.Hearts: {
      return 16;
    }
    case Suit.Diamonds: {
      return 32;
    }
    case Suit.Clubs: {
      return 48;
    }
  }
}

function getUnicodeAndColorForCard({value, suit}: Card): [string, string] {
  let color;
  switch(suit) {
    case Suit.Clubs:
    case Suit.Spades: {
      color = "black";
      break;
    }
    case Suit.Hearts:
    case Suit.Diamonds: {
      color = "red";
      break;
    }
  }

  const offset = suitToOffset(suit);
  const code = getCardCode(offset + value - 1);
  return [code, color];
}

export function PlayerCard({ card, onClick }: PlayerCardProps) {
  const [code, color] = getUnicodeAndColorForCard(card);
  const style = useMemo(() => {
    return {
      cursor: 'pointer',
      color,
      fontSize: '8em',
    }
  }, [color])
  return (
    <div onClick={onClick} style={style}>
      <span dangerouslySetInnerHTML={{__html: code}} />
    </div>
  );
}

interface HiddenCardProps {
  position: "top" | "side";
}

export function HiddenCard({ position }: HiddenCardProps) {
  const style = useMemo(() => {
    return {
      fontSize: '6em',
      transform: position === 'top' ? undefined : 'rotate(90deg)'
    };
  }, [position]);
  return (
    <div style={style}>
      <span dangerouslySetInnerHTML={{__html: '&#127136;'}} />
    </div>
  );
}
