import * as React from "react";
import { useCallback } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import {
  Card,
  PublicPlayer,
  Position,
  addBot,
  joinGame,
  selectCurrentPlayer,
  selectError,
  selectIsCreator,
  selectLastTrick,
  selectOrderedPlayers,
  selectPlayerCards,
  selectPlayerCardsRevealed,
  selectPlayerPositions,
  selectPlayersById,
} from "./features/game/gameSlice";
import { selectUsername } from "./features/user/userSlice";
import { useAppDispatch } from "./app/store";

import EventStream from "./EventStream";
import PlayArea from "./PlayArea";
import { Bold } from "./Text";
import { Button } from "./Button";
import { HiddenHand } from "./Hand";
import { Marker } from "./Marker";
import { PlayerHand } from "./Hand";
import { PlayingCard } from "./Card";
import { Panel, PanelBody } from "./Panel";
import { Column, Container, HorizontalLayout, VerticalLayout } from "./Layout";

function GameView() {
  const username = useSelector(selectUsername);
  const playerCards = useSelector(selectPlayerCards);
  const playerCardsRevealed = useSelector(selectPlayerCardsRevealed);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const lastTrick = useSelector(selectLastTrick);
  const playersById = useSelector(selectPlayersById);
  const error = useSelector(selectError);
  const [bottomPlayer, leftPlayer, topPlayer, rightPlayer] =
    useSelector(selectOrderedPlayers);
  const canJoin = !playerCards || !(bottomPlayer?.name === username);
  const isCreator = useSelector(selectIsCreator);

  return (
    <HorizontalLayout flexGrow={1}>
      <Column width={1}>
        <GamePosition
          canAddBot={isCreator && !leftPlayer}
          canJoin={canJoin}
          orientation="right"
          player={leftPlayer}
          position={Position.East}
        />
      </Column>
      <Column width={8}>
        <VerticalLayout height="100%">
          <GamePosition
            canAddBot={isCreator && !topPlayer}
            canJoin={canJoin}
            orientation="top"
            player={topPlayer}
            position={Position.South}
          />
          <PlayArea />
          {playerCards && bottomPlayer ? (
            <Self
              call={bottomPlayer.call}
              cards={playerCards}
              current={currentPlayer?.name === bottomPlayer.name}
              name={username || ""}
              position="top"
              revealed={playerCardsRevealed}
              tricks={bottomPlayer.tricks}
            />
          ) : (
            <GamePosition
              canAddBot={isCreator && !bottomPlayer}
              canJoin={canJoin}
              orientation="top"
              player={bottomPlayer}
              position={Position.North}
            />
          )}
        </VerticalLayout>
      </Column>
      <Column width={1}>
        <Container height="100%">
          <GamePosition
            canAddBot={isCreator && !rightPlayer}
            canJoin={canJoin}
            orientation="left"
            player={rightPlayer}
            position={Position.West}
          />
        </Container>
      </Column>
      <Column width={2}>
        <VerticalLayout>
          {error && (
            <Panel>
              <PanelBody>
                <span>
                  <strong>Error: </strong>
                  {error}
                </span>
              </PanelBody>
            </Panel>
          )}
          {lastTrick && lastTrick.length > 0 && (
            <VerticalLayout>
              <Bold>Last trick:</Bold>
              <HorizontalLayout flexWrap="wrap">
                {lastTrick.map(({ id, card }) => (
                  <VerticalLayout key={id} alignItems="center">
                    <div>{playersById[id]?.name || id}</div>
                    <PlayingCard card={card} ratio={4} />
                  </VerticalLayout>
                ))}
              </HorizontalLayout>
            </VerticalLayout>
          )}
          <EventStream />
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
  position: "top" | "left" | "right";
  tricks?: number;
}

interface SelfProps extends PlayerProps<Card[]> {
  revealed: boolean;
}

const selfStyle = {
  border: "1px solid lightgray",
  borderRadius: 2,
  paddingBottom: 10,
};

const Self = ({ call, cards, current, name, revealed, tricks }: SelfProps) => (
  <span style={selfStyle}>
    <VerticalLayout>
      <HorizontalLayout alignItems="center" justifyContent="space-between">
        <HorizontalLayout alignItems="center">
          <span>{name}</span>
          {current && <Marker />}
        </HorizontalLayout>
        {call && tricks !== undefined && (
          <div style={{ flexShrink: 0 }}>
            {`${tricks} of ${callToString(call)}`}
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

interface PositionContainerProps {
  alignItems?: "center";
  children: React.ReactNode;
  justifyContent?: "center";
  position: "top" | "left" | "right";
}

const PositionContainer = ({
  alignItems,
  children,
  justifyContent,
  position,
}: PositionContainerProps) => {
  const Component = position === "top" ? VerticalLayout : HorizontalLayout;
  return (
    <Component
      alignItems={alignItems}
      border="1px solid lightgray"
      borderRadius={2}
      height={position !== "top" ? "85%" : undefined}
      justifyContent={justifyContent}
      width={position === "top" ? "100%" : undefined}
    >
      {children}
    </Component>
  );
};

export function callToString(call: number): string {
  switch (call) {
    case -2:
      return "Blind Nil";
    case -1:
      return "Nil";
    default:
      return call.toString();
  }
}

const Player = ({
  call,
  cards,
  current,
  name,
  position,
  tricks,
}: PlayerProps<number>) => {
  if (position === "left" || position === "right") {
    return (
      <VerticalLayout
        alignItems="center"
        justifyContent="space-evenly"
        height="90%"
      >
        <HorizontalLayout alignItems="center">
          <span>{name}</span>
          {current && <Marker />}
        </HorizontalLayout>
        <HiddenHand cards={cards} position={position} />
        {call !== null && call !== undefined && tricks !== undefined && (
          <div style={{ flexShrink: 0 }}>
            <span>{`${tricks} of ${callToString(call)}`}</span>
          </div>
        )}
      </VerticalLayout>
    );
  }

  return (
    <VerticalLayout alignItems="center" justifyContent="center" width="100%">
      <HiddenHand cards={cards} position={position} />
      <HorizontalLayout justifyContent="space-between">
        <HorizontalLayout alignItems="center">
          <span>{name}</span>
          {current && <Marker />}
        </HorizontalLayout>
        {call !== null && call !== undefined && tricks !== undefined && (
          <div style={{ flexShrink: 0 }}>
            {`${tricks} of ${callToString(call)}`}
          </div>
        )}
      </HorizontalLayout>
    </VerticalLayout>
  );
};

interface GamePositionProps {
  canAddBot: boolean;
  canJoin: boolean;
  orientation: "top" | "left" | "right";
  player?: PublicPlayer;
  position: Position;
}

const GamePosition = ({
  canJoin,
  orientation,
  player,
  position,
}: GamePositionProps) => {
  const currentPlayer = useSelector(selectCurrentPlayer);
  const playerPositions = useSelector(selectPlayerPositions);
  if (player) {
    return (
      <Player
        call={player.call}
        cards={player.cards}
        current={currentPlayer?.name === player.name}
        name={player.name}
        position={orientation}
        tricks={player.tricks}
      />
    );
  } else if (canJoin && playerPositions && !playerPositions[position]) {
    return (
      <PositionContainer
        alignItems="center"
        justifyContent="center"
        position={orientation}
      >
        <JoinPosition position={position} />
      </PositionContainer>
    );
  }
  return (
    <PositionContainer
      alignItems="center"
      justifyContent="center"
      position={orientation}
    >
      <AddBotButton position={position} />
    </PositionContainer>
  );
};

interface JoinPositionProps {
  position: Position;
}

const JoinPosition = ({ position }: JoinPositionProps) => {
  const dispatch = useAppDispatch();
  const username = useSelector(selectUsername);
  const { id } = useParams();

  const join = useCallback(() => {
    if (id && username) {
      dispatch(joinGame({ id: parseInt(id), position, username }));
    }
  }, [dispatch, id, position, username]);
  return <Button onClick={join}>Join</Button>;
};

const AddBotButton = ({ position }: JoinPositionProps) => {
  const dispatch = useAppDispatch();
  const { id } = useParams();

  const join = useCallback(() => {
    if (id) {
      dispatch(addBot({ id: parseInt(id), position }));
    }
  }, [dispatch, id, position]);
  return <Button onClick={join}>Add Bot</Button>;
};

export default GameView;
