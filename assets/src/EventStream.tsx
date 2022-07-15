import * as React from "react";
import { useSelector } from "react-redux";

import { selectEvents, selectPlayersById } from "./features/game/gameSlice";

import { Bold } from "./Text";
import { Container, PaddedVerticalLayout } from "./Layout";
import { useDelayedRemove } from "./useDelayedRemove";
import { cardToString } from "./Card";

function EventStream() {
  const events = useSelector(selectEvents);
  const playersById = useSelector(selectPlayersById);
  const eventStream = useDelayedRemove(events);

  return (
    <PaddedVerticalLayout padding={5}>
      <Bold>Events:</Bold>
      <PaddedVerticalLayout padding={2}>
        {eventStream.map((event, index) => {
          const eventText = `${index}-${JSON.stringify(event)}`;
          switch (event.type) {
            case "called": {
              return (
                <GameEvent key={eventText}>
                  {playersById[event.data.player]?.name || event.data.player}{" "}
                  called {event.data.call}
                </GameEvent>
              );
            }
            case "hand_ended": {
              return <GameEvent key={eventText}>Hand ended</GameEvent>;
            }
            case "dealt_cards": {
              return <GameEvent key={eventText}>Dealt cards</GameEvent>;
            }
            case "played_card": {
              return (
                <GameEvent key={eventText}>
                  {playersById[event.data.player]?.name || event.data.player}{" "}
                  played {cardToString(event.data.card)}
                </GameEvent>
              );
            }
            case "round_ended": {
              return <GameEvent key={eventText}>Round ended</GameEvent>;
            }
            case "awarded_trick": {
              return (
                <GameEvent key={eventText}>
                  Awarded trick to{" "}
                  {playersById[event.data.winner]?.name || event.data.winner}
                </GameEvent>
              );
            }
            case "state_changed": {
              return (
                <GameEvent key={eventText}>
                  <>Game changed from {event.data.old} to {event.data.new}</>
                </GameEvent>
              );
            }
            case "revealed_cards": {
              return (
                <GameEvent key={eventText}>
                  {playersById[event.data.player]?.name || event.data.player}{" "}
                  revealed their hand
                </GameEvent>
              );
            }
            default: {
              throw new Error("Unexpected event");
            }
          }
        })}
      </PaddedVerticalLayout>
    </PaddedVerticalLayout>
  );
}

export default EventStream;

function GameEvent({ children }: React.PropsWithChildren<{}>) {
  return (
    <Container borderRadius={3} border="1px solid lightgray" padding="2 4">
      {children}
    </Container>
  );
}
