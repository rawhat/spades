import { AnyAction } from "redux";
import { Channel } from "phoenix";
import { Dispatch } from "redux";
import { Socket } from "phoenix";

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

export const gameSocketMiddleware = (_store: any) => (next: Dispatch) => {
  let socket = new Socket("/socket/game");
  socket.connect();

  let channel: Channel;

  return (action: AnyAction) => {
    if (observeGame.match(action)) {
      const params = action.payload;
      channel = socket.channel(`game:${params.id}`, { params });

      channel
        .join()
        .receive("ok", (msg: PlayerStatus) => {
          if (msg.team !== undefined) {
            next(setPlayerState(msg));
          } else {
            next(setGameState(msg));
          }
        })
        .receive("err", (err: any) => {
          next(socketError(err));
        });

      channel.on("game_state", ({ events, state }: GameStatePayload) => {
        if ((state as PlayerStatus).team !== undefined) {
          next(setPlayerState(state as PlayerStatus));
        } else {
          next(setGameState(state));
        }
        next(setEvents(events));
      });

      next(setConnected());
    } else if (joinGame.match(action)) {
      channel
        .push("join_game", { body: action.payload })
        .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (addBot.match(action)) {
      next(clearError());
      channel
        .push("add_bot", { body: action.payload })
        .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (revealCards.match(action)) {
      next(clearError());
      channel
        .push("reveal", { body: {} })
        .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (makeCall.match(action)) {
      next(clearError());
      channel
        .push("make_call", { body: action.payload })
        .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    } else if (playCard.match(action)) {
      next(clearError());
      channel
        .push("play_card", { body: action.payload })
        .receive("error", ({ reason }: ErrorPayload) => next(setError(reason)));
    }

    next(action);
  };
};
