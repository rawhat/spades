import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
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

import EventStream from "./EventStream";
import PlayArea from "./PlayArea";
import { Bold } from "./Text";
import { Button } from "./Button";
import { HiddenHand } from "./Hand";
import { Marker } from "./Marker";
import { PlayerHand } from "./Hand";
import { PlayingCard } from "./Card";
import { Panel, PanelBody, PanelFooter, PanelHeader } from "./Panel";
import { Column, HorizontalLayout, SubHeader, VerticalLayout } from "./Layout";

function GameView() {
  const username = useSelector(selectUsername);
  const playerCards = useSelector(selectPlayerCards);
  const playerCardsRevealed = useSelector(selectPlayerCardsRevealed);
  const currentPlayer = useSelector(selectCurrentPlayer);
  const lastTrick = useSelector(selectLastTrick);
  const playersById = useSelector(selectPlayersById);
  const error = useSelector(selectError);
  const [bottomPlayer, leftPlayer, topPlayer, rightPlayer] = useSelector(
    selectOrderedPlayers
  );
  const canJoin = !playerCards || !(bottomPlayer?.name === username);
  const isCreator = useSelector(selectIsCreator);

  return (
    <HorizontalLayout flexGrow={1}>
      <Column width={1}>
        <GamePosition
          canAddBot={isCreator && !leftPlayer}
          canJoin={canJoin}
          orientation="side"
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
        <GamePosition
          canAddBot={isCreator && !rightPlayer}
          canJoin={canJoin}
          orientation="side"
          player={rightPlayer}
          position={Position.West}
        />
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
                {lastTrick.map(({ player_id, card }) => (
                  <VerticalLayout key={player_id}>
                    <div>{playersById[player_id]?.name || player_id}</div>
                    <PlayingCard card={card} size={3} />
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
  position: "top" | "side";
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
          <>{name}</>
          {current && <Marker />}
        </HorizontalLayout>
        {call !== null && tricks !== undefined && (
          <div style={{ flexShrink: 0 }}>{`${tricks} of ${call}`}</div>
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
  position: "top" | "side";
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

const Player = ({
  call,
  cards,
  current,
  name,
  position,
  tricks,
}: PlayerProps<number>) => {
  const NameComponent = position === "top" ? HorizontalLayout : VerticalLayout;
  return (
    <PositionContainer position={position}>
      <HiddenHand cards={cards} position={position} />
      <NameComponent justifyContent="space-between">
        <HorizontalLayout alignItems="center">
          <>{name}</>
          {current && <Marker />}
        </HorizontalLayout>
        {call !== null && tricks !== undefined && (
          <div style={{ flexShrink: 0 }}>{`${tricks} of ${call}`}</div>
        )}
      </NameComponent>
    </PositionContainer>
  );
};

interface GamePositionProps {
  canAddBot: boolean;
  canJoin: boolean;
  orientation: "side" | "top";
  player?: PublicPlayer;
  position: Position;
}

const GamePosition = ({
  canAddBot,
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
  const dispatch = useDispatch();
  const username = useSelector(selectUsername);
  const { id } = useParams();

  const join = useCallback(() => {
    if (id && username) {
      dispatch(joinGame({ id, position, username }));
    }
  }, [dispatch, id, position, username]);
  return <Button onClick={join}>Join</Button>;
};

const AddBotButton = ({ position }: JoinPositionProps) => {
  const dispatch = useDispatch();
  const { id } = useParams();

  const join = useCallback(() => {
    if (id) {
      dispatch(addBot({ position }));
    }
  }, [dispatch, id, position]);
  return <Button onClick={join}>Add Bot</Button>;
};

export default GameView;
