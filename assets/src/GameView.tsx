import * as React from "react";
import { useSelector } from "react-redux";

import {
  Card,
  selectCurrentPlayer,
  selectError,
  selectOrderedPlayers,
  selectPlayerCards,
  selectPlayerCardsRevealed,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";

import PlayArea from "./PlayArea";
import { HiddenHand } from "./Hand";
import { Marker } from "./Marker";
import { PlayerHand } from "./Hand";
import { Panel, PanelBody, PanelFooter, PanelHeader } from "./Panel";
import { Column, HorizontalLayout, SubHeader, VerticalLayout } from "./Layout";

function GameView() {
  const username = useSelector(selectUsername);
  const playerCards = useSelector(selectPlayerCards);
  const playerCardsRevealed = useSelector(selectPlayerCardsRevealed);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const error = useSelector(selectError);
  const [self, leftPlayer, teammate, rightPlayer] = useSelector(selectOrderedPlayers);

  return (
    <HorizontalLayout flexGrow={1}>
      <Column width={1}>
        {leftPlayer && (
          <Player
            call={leftPlayer?.call}
            cards={leftPlayer.cards}
            current={currentPlayer?.name === leftPlayer?.name}
            name={leftPlayer.name}
            position="side"
            tricks={leftPlayer?.tricks}
          />
        )}
      </Column>
      <Column width={8}>
        <VerticalLayout height="100%">
          {teammate && (
            <Player
              call={teammate?.call}
              cards={teammate.cards}
              current={currentPlayer?.name === teammate?.name}
              name={teammate.name}
              position="top"
              tricks={teammate?.tricks}
            />
          )}
          <PlayArea />
          {playerCards && (
            <Self
              call={self?.call}
              cards={playerCards}
              current={currentPlayer?.name === self?.name}
              name={username || ""}
              position="top"
              revealed={playerCardsRevealed}
              tricks={self?.tricks}
            />
          )}
        </VerticalLayout>
      </Column>
      <Column width={1}>
        {rightPlayer && (
          <Player
            call={rightPlayer?.call}
            cards={rightPlayer.cards}
            current={currentPlayer?.name === rightPlayer?.name}
            name={rightPlayer.name}
            position="side"
            tricks={rightPlayer?.tricks}
          />
        )}
      </Column>
      <Column width={2}>
        <VerticalLayout>
          <Panel>
            <PanelHeader>
              <SubHeader>Chat</SubHeader>
            </PanelHeader>
            <PanelBody>
              <div>This is the chat text.</div>
            </PanelBody>
            <PanelFooter>This will be an input.</PanelFooter>
          </Panel>
          {error && (
            <Panel>
              <PanelBody>
                <span><strong>Error:  </strong>{error}</span>
              </PanelBody>
            </Panel>
          )}
        </VerticalLayout>
      </Column>
    </HorizontalLayout>
  );
}

interface PlayerProps<T> {
  call?: number;
  cards: T;
  name: string;
  current: boolean;
  position: "top" | "side";
  tricks?: number;
}

interface SelfProps extends PlayerProps<Card[]> {
  revealed: boolean;
}

const selfStyle = {
  paddingBottom: 10,
};

const Self = ({ call, cards, current, name, revealed, tricks }: SelfProps) => (
  <span style={selfStyle}>
    <VerticalLayout>
      <HorizontalLayout alignItems="center" justifyContent="space-between">
        <HorizontalLayout alignItems="center">
          <>{name}</>
          {current && <Marker />}
        </HorizontalLayout>
        {call !== null && tricks !== undefined && (
          <div style={{flexShrink: 0}}>
            {`${tricks} of ${call}`}
          </div>
        )}
      </HorizontalLayout>
      {revealed ? (
        <PlayerHand cards={cards} />
      ) : (
        <HiddenHand cards={13} position="top" />
      )}
    </VerticalLayout>
  </span>
);

const Player = ({
  call,
  cards,
  current,
  name,
  position,
  tricks,
}: PlayerProps<number>) => {
  const Component = position === "top" ? VerticalLayout : HorizontalLayout;
  const NameComponent = position === "top" ? HorizontalLayout : VerticalLayout;
  return (
    <Component
      height={position !== "top" ? "100%" : undefined}
      width={position === "top" ? "100%" : undefined}
    >
      <HiddenHand cards={cards} position={position} />
      <NameComponent>
        <HorizontalLayout alignItems="center">
          <>{name}</>
          {current && <Marker />}
        </HorizontalLayout>
        {call !== null && tricks !== undefined && (
          <div style={{flexShrink: 0}}>
            {`${tricks} of ${call}`}
          </div>
        )}
      </NameComponent>
    </Component>
  );
};

export default GameView;
