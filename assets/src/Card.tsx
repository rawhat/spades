import * as React from "react";
import { useMemo } from "react";

import { Card, Suit } from "./features/game/gameSlice";

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

  // The unicode character set contains the "Knight" card, between Jack and
  // Queen.  So we need to add an additional index here to skip over it.
  let v = value === 12 || value === 13 ? value + 1 : value;

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
  fontSize: "8em",
};

export function EmptyCard() {
  return (
    <div style={emptyStyle}>
      <span dangerouslySetInnerHTML={{ __html: "&nbsp;" }} />
    </div>
  );
}
