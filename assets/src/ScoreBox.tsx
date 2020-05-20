import * as React from "react";
import get from "lodash/get";
import { useSelector } from "react-redux";

import { Team, selectScores } from "./features/game/gameSlice";

import { HorizontalLayout, SubHeader, VerticalLayout } from "./Layout";

const scoreBoxStyle: React.CSSProperties = {
  position: "absolute",
  right: 0,
  bottom: 50,
  height: "20%",
};

const padding = {
  paddingRight: 5,
};

function ScoreBox() {
  const scores = useSelector(selectScores);
  const team_one = get(scores, Team.NorthSouth);
  const team_two = get(scores, Team.EastWest);
  return (
    <div style={scoreBoxStyle}>
      <VerticalLayout>
        <SubHeader>Scores</SubHeader>
        <HorizontalLayout justifyContent="space-between">
          <span style={padding}>
            <b>North/South</b>
          </span>
          <span>{team_one}</span>
        </HorizontalLayout>
        <HorizontalLayout justifyContent="space-between">
          <span style={padding}>
            <b>East/West</b>
          </span>
          <span>{team_two}</span>
        </HorizontalLayout>
      </VerticalLayout>
    </div>
  );
}

export default ScoreBox;
