import { AnyAction } from "redux";
import { Dispatch } from "redux";

import {
  Event,
  GameStatus,
  PlayerStatus,
  addBot,
  clearError,
  joinGame,
  makeCall,
  observeGame,
  playCard,
  revealCards,
  setConnected,
  setError,
  setEvents,
  setGameState,
  setPlayerState,
  socketError,
} from "./gameSlice";

interface ErrorPayload {
  reason: string;
}

interface GameStatePayload {
  events: any[];
  state: PlayerStatus | GameStatus;
}

type GameMessage =
  | { type: "player_state"; data: PlayerStatus; events: Event[] }
  | { type: "game_state"; data: GameStatus; events: Event[] };

export const gameSocketMiddleware = (_store: any) => (next: Dispatch) => {
  let socket: WebSocket;

  return (action: AnyAction) => {
    if (observeGame.match(action)) {
      const params = action.payload;
      socket = new WebSocket(`ws://localhost:4000/socket/game/${params.id}`);

      socket.onmessage = ({ data }: MessageEvent<string>) => {
        const msg: GameMessage = JSON.parse(data);
        if (msg.type === "player_state") {
          next(setPlayerState(msg.data));
        } else {
          next(setGameState(msg.data));
        }
        next(setEvents(msg.events));
      };
      next(setConnected());
    } else if (joinGame.match(action)) {
      socket.send(JSON.stringify({ type: "add_player", data: action.payload }));
    } else if (addBot.match(action)) {
      next(clearError());
      socket.send(JSON.stringify({ type: "add_bot", data: action.payload }));
    } else if (revealCards.match(action)) {
      next(clearError());
      socket.send(
        JSON.stringify({ type: "reveal_hand", data: action.payload })
      );
    } else if (makeCall.match(action)) {
      next(clearError());
      socket.send(JSON.stringify({ type: "make_call", data: action.payload }));
    } else if (playCard.match(action)) {
      next(clearError());
      socket.send(JSON.stringify({ type: "play_card", data: action.payload }));
    }

    next(action);
  };
};
