import * as React from "react";
import get from "lodash/get";
import { useSelector } from "react-redux";

import { Team, selectScores } from "./features/game/gameSlice";

import { HorizontalLayout, SubHeader, VerticalLayout } from "./Layout";

const scoreBoxStyle: React.CSSProperties = {
  position: "absolute",
  right: 0,
  bottom: 50,
  width: "10%",
  height: "20%",
};

function ScoreBox() {
  const scores = useSelector(selectScores);
  const team_one = get(scores, Team.One);
  const team_two = get(scores, Team.Two);
  return (
    <div style={scoreBoxStyle}>
      <VerticalLayout>
        <SubHeader>Scores</SubHeader>
        <HorizontalLayout justifyContent="space-between">
          <span>
            <b>Team One</b>
          </span>
          <span>{team_one}</span>
        </HorizontalLayout>
        <HorizontalLayout justifyContent="space-between">
          <span>
            <b>Team Two</b>
          </span>
          <span>{team_two}</span>
        </HorizontalLayout>
      </VerticalLayout>
    </div>
  );
}

export default ScoreBox;
