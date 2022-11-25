import { AnyAction } from "redux";
import { Dispatch } from "redux";

import {
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
  | { type: "player_state"; data: PlayerStatus }
  | { type: "game_state"; data: GameStatus };

export const gameSocketMiddleware = (_store: any) => (next: Dispatch) => {
  let socket: WebSocket;

  return (action: AnyAction) => {
    if (observeGame.match(action)) {
      const params = action.payload;
      socket = new WebSocket(`ws://localhost:4000/socket/game/${params.id}`);

      socket.onmessage = ({ data }: MessageEvent<string>) => {
        console.log("got some data", data);
        const msg: GameMessage = JSON.parse(data);
        if (msg.type === "player_state") {
          next(setPlayerState(msg.data));
        } else {
          next(setGameState(msg.data));
        }
      };

      // channel
      //   .join()
      //   .receive("ok", (msg: PlayerStatus) => {
      //     if (msg.team !== undefined) {
      //       next(setPlayerState(msg));
      //     } else {
      //       next(setGameState(msg));
      //     }
      //   })
      //   .receive("error", (err: any) => {
      //     next(socketError(err));
      //   });
      //
      // channel.on("game_state", ({ events, state }: GameStatePayload) => {
      //   if ((state as PlayerStatus).team !== undefined) {
      //     next(setPlayerState(state as PlayerStatus));
      //   } else {
      //     next(setGameState(state));
      //   }
      //   next(setEvents(events));
      // });

      next(setConnected());
    } else if (joinGame.match(action)) {
      socket.send(JSON.stringify({ type: "add_player", data: action.payload }));
      // channel
      //   .push("join_game", { body: action.payload })
      //   .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (addBot.match(action)) {
      next(clearError());
      // channel
      //   .push("add_bot", { body: action.payload })
      //   .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (revealCards.match(action)) {
      next(clearError());
      socket.send(
        JSON.stringify({ type: "reveal_hand", data: action.payload })
      );
      // channel
      //   .push("reveal", { body: {} })
      //   .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (makeCall.match(action)) {
      next(clearError());
      socket.send(JSON.stringify({ type: "make_call", data: action.payload }));
      // channel
      //   .push("make_call", { body: action.payload })
      //   .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (playCard.match(action)) {
      next(clearError());
      socket.send(JSON.stringify({ type: "play_card", data: action.payload }));
      // channel
      //   .push("play_card", { body: action.payload })
      //   .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    }

    next(action);
  };
};
