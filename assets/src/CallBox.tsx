import * as React from "react";
import range from "lodash/range";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useSelector } from "react-redux";
import { useState } from "react";

import {
  makeCall,
  revealCards,
  selectCurrentPlayer,
  selectPlayerCardsRevealed,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import viewStyle from "./CallBox.module.css";

type Call = -1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13;

function CallBox() {
  const [call, setCall] = useState<Call>();
  const dispatch = useDispatch();

  const currentPlayer = useSelector(selectCurrentPlayer);
  const username = useSelector(selectUsername);
  const cardsRevealed = useSelector(selectPlayerCardsRevealed);
  const currentlyBidding = currentPlayer?.name === username;

  const getOnClick = useCallback(
    (value: Call) => {
      return () => (call === value ? setCall(undefined) : setCall(value));
    },
    [call]
  );

  const onSubmit = useCallback(() => {
    if (call !== undefined) {
      dispatch(makeCall(call));
    }
  }, [call, dispatch]);

  let revealButton = (
    <Call onClick={() => dispatch(revealCards())}>Reveal</Call>
  )

  if (!currentlyBidding && cardsRevealed) {
    return null;
  }

  if (!currentlyBidding && !cardsRevealed) {
    return (
      <div className={viewStyle.callBox}>
        {revealButton}
      </div>
    )
  }

  if (!cardsRevealed) {
    return (
      <div className={viewStyle.callBox}>
        <Call onClick={getOnClick(-1)} selected={call === -1}>
          Blind Nil
        </Call>
        {revealButton}
        <Call onClick={onSubmit}>Submit</Call>
      </div>
    );
  }

  return (
    <div className={viewStyle.callBox}>
      {range(0, 14).map((value) => (
        <Call
          key={value}
          onClick={getOnClick(value as Call)}
          selected={value === call}
        >
          {value.toString()}
        </Call>
      ))}
      <Call onClick={onSubmit}>Submit</Call>
    </div>
  );
}

export default CallBox;

interface CallProps {
  children: string;
  onClick: () => void;
  selected?: boolean;
}

const selectedBackground = { backgroundColor: "lightblue" };

function Call({ onClick, children, selected }: CallProps) {
  return (
    <div
      className={viewStyle.call}
      onClick={onClick}
      style={selected ? selectedBackground : {}}
    >
      <span>{children}</span>
    </div>
  );
}
