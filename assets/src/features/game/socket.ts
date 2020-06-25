import { AnyAction } from "redux";
import { Channel } from "phoenix";
import { Dispatch } from "redux";
import { Socket } from "phoenix";

import {
  GameStatus,
  PlayerStatus,
  clearError,
  joinGame,
  makeCall,
  observeGame,
  playCard,
  revealCards,
  setConnected,
  setError,
  setGameState,
  setPlayerState,
  socketError,
} from "./gameSlice";

interface ErrorPayload {
  reason: string;
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
          console.log("received ok", msg);
          if (msg.team !== undefined) {
            next(setPlayerState(msg));
          } else {
            next(setGameState(msg));
          }
        })
        .receive("err", (err: any) => {
          next(socketError(err));
        });

      channel.on("game_state", (payload: PlayerStatus | GameStatus) => {
        if ((payload as PlayerStatus).team !== undefined) {
          next(setPlayerState(payload as PlayerStatus));
        } else {
          next(setGameState(payload));
        }
      });

      next(setConnected());
    } else if (joinGame.match(action)) {
      channel
        .push("join_game", { body: action.payload })
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
