import { AnyAction } from "redux";
import { Channel } from "phoenix";
import { Dispatch } from "redux";
import { Socket } from "phoenix";

import {
  GameStatus,
  PlayerStatus,
  joinGame,
  setGameState,
  setPlayerState,
  socketError,
  revealCards,
  makeCall,
  playCard
} from "./gameSlice";

export const socketMiddleware = (_store: any) => (next: Dispatch) => {
  let socket = new Socket("/socket/game");
  socket.connect();

  let channel: Channel;

  return (action: AnyAction) => {
    if (joinGame.match(action)) {
      const params = action.payload;
      channel = socket.channel(`game:${params.id}`, {params});

      channel.join()
        .receive("ok", (msg: PlayerStatus) => {
          console.log("connected", msg);
          if (msg.team !== undefined) {
            next(setPlayerState(msg));
          } else {
            next(setGameState(msg));
          }
        })
        .receive("err", (err: any) => {
          console.error("error", err);
          next(socketError(err));
        });

      channel.on("game_state", (payload: PlayerStatus | GameStatus) => {
        if ((payload as PlayerStatus).team !== undefined) {
          console.log("player state")
          next(setPlayerState(payload as PlayerStatus));
        } else {
          console.log("game state")
          next(setGameState(payload));
        }
      });

      channel.push("join_game", {body: action.payload})
    } else if (revealCards.match(action)) {
      channel.push("reveal", {body: {}})
    } else if (makeCall.match(action)) {
      channel.push("make_call", {body: action.payload});
    } else if (playCard.match(action)) {
      channel.push("play_card", {body: action.payload})
    }

    next(action);
  }
}
