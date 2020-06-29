import * as React from "react";
import { useMemo } from "react";
import get from "lodash/get";
import { useSelector } from "react-redux";

import { Team, selectScores, selectSelf } from "./features/game/gameSlice";

import {
  HorizontalLayout,
  PaddedHorizontalLayout,
  SubHeader,
  VerticalLayout,
} from "./Layout";

const scoreBoxStyle: React.CSSProperties = {
  position: "absolute",
  right: 0,
  bottom: 50,
  height: "20%",
};

function ScoreBox() {
  const scores = useSelector(selectScores);
  const self = useSelector(selectSelf);

  const teamOne = get(scores, Team.NorthSouth);
  const teamTwo = get(scores, Team.EastWest);

  const hasTeam = self && self.team;
  let teamOneIndicator;
  let teamTwoIndicator;
  if (hasTeam) {
    teamOneIndicator = <Indicator enabled={false} />;
    teamTwoIndicator = <Indicator enabled={false} />;
    if (self?.team === Team.NorthSouth) {
      teamOneIndicator = <Indicator />;
    } else if (self?.team === Team.EastWest) {
      teamTwoIndicator = <Indicator />;
    }
  }

  return (
    <div style={scoreBoxStyle}>
      <VerticalLayout>
        <SubHeader>Scores</SubHeader>
        <HorizontalLayout>
          {teamOneIndicator}
          <PaddedHorizontalLayout justifyContent="space-between" padding={5}>
            <b>North/South</b>
            <span>{teamOne}</span>
          </PaddedHorizontalLayout>
        </HorizontalLayout>
        <HorizontalLayout>
          {teamTwoIndicator}
          <PaddedHorizontalLayout justifyContent="space-between" padding={5}>
            <b>East/West</b>
            <span>{teamTwo}</span>
          </PaddedHorizontalLayout>
        </HorizontalLayout>
      </VerticalLayout>
    </div>
  );
}

export default ScoreBox;

const circle = "&#11044;";

function Indicator({ enabled = true }) {
  const circleStyle = useMemo(
    () => ({
      color: enabled ? "lightblue" : "white",
    }),
    [enabled]
  );
  return (
    <span dangerouslySetInnerHTML={{ __html: circle }} style={circleStyle} />
  );
}
