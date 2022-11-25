import * as React from "react";
import { useMemo } from "react";

import { Card, Suit } from "./features/game/gameSlice";

export function cardToString(card: Card): string {
  return `${card.value} of ${card.suit}`;
}

const initialCode = 127137;
function getCardCode(offset: number) {
  return `&#${initialCode + offset};`;
}

function suitToOffset(suit: Suit): number {
  switch (suit) {
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

function valueFromString(value: string): number {
  switch (value) {
    case "A":
      return 1;
    case "K":
      return 13;
    case "Q":
      return 12;
    case "J":
      return 11;
    default:
      return parseInt(value);
  }
}

function getUnicodeAndColorForCard({ value, suit }: Card): [string, string] {
  let color;
  switch (suit) {
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

  const valueNumber = valueFromString(value);

  // The unicode character set contains the "Knight" card, between Jack and
  // Queen.  So we need to add an additional index here to skip over it.
  let v =
    valueNumber === 12 || valueNumber === 13 ? valueNumber + 1 : valueNumber;

  const code = getCardCode(offset + v - 1);
  return [code, color];
}

interface PlayerCardProps {
  card: Card;
  onClick?: () => void;
  size?: number;
}

export function PlayingCard({ card, onClick, size = 8 }: PlayerCardProps) {
  const [code, color] = getUnicodeAndColorForCard(card);
  const style = useMemo(() => {
    return {
      cursor: onClick && "pointer",
      color,
      fontSize: `${size}em`,
    };
  }, [color, onClick, size]);
  return (
    <div onClick={onClick} style={style}>
      <span dangerouslySetInnerHTML={{ __html: code }} />
    </div>
  );
}

const emptyStyle = {
  opacity: 0,
  fontSize: "8em",
};

const knightSpades = getCardCode(suitToOffset(Suit.Spades) + 11);

export function EmptyCard() {
  return (
    <div style={emptyStyle}>
      <span dangerouslySetInnerHTML={{ __html: knightSpades }} />
    </div>
  );
}
