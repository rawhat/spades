import * as React from "react";
import range from "lodash/range";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useState } from "react";

import { revealCards, makeCall } from "./features/game/gameSlice";

import viewStyle from "./CallBox.module.css";

interface CallBoxProps {
  revealed: boolean;
}

type Call = -1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13;

function CallBox({ revealed }: CallBoxProps) {
  const [call, setCall] = useState<Call>();
  const dispatch = useDispatch();

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

  if (!revealed) {
    return (
      <div className={viewStyle.callBox}>
        <Call onClick={getOnClick(-1)} selected={call === -1}>
          Blind Nil
        </Call>
        <Call onClick={() => dispatch(revealCards())}>Reveal</Call>
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
