import React from "react";
import { Channel } from "phoenix";
import { Socket } from "phoenix";
import { useContext } from "react";
import { useEffect } from "react";
import { useState } from "react";

import { Card } from "./features/game/gameSlice";
import { PlayerStatus } from "./features/game/gameSlice";
import { Team } from "./features/game/gameSlice";
//import { getPlayerState } from "./features/game/gameSlice";

export const SocketProvider = React.createContext(null);

export const useSocket = () => useContext(SocketProvider);

export const useGameState = (id?: string, username?: string) => {
  const [socket, setSocket] = useState<Socket>();
  const [channel, setChannel] = useState<Channel>();
  const [error, setError] = useState<string>();
  const [state, setState] = useState<PlayerStatus>();

  useEffect(() => {
    if (id && !socket) {
      const socket = new Socket("/socket/game");
      socket.connect();
      setSocket(socket);

      const params: {username?: string} = {};
      if (username) {
        params.username = username;
      }
      const channel = socket.channel(`game:${id}`, {params});
      channel.join()
        .receive("ok", (msg: PlayerStatus) => {
          console.log("connected!", msg);
          setChannel(channel);
          setState(msg);
        })
        .receive("err", (err: any) => {
          console.error(":(", err);
          setError(err);
        });

      channel.on("game_state", payload => {
        console.log("got new payload", payload);
        setState(payload);
      })
    }
    return () => {
      setChannel(undefined);
      setError(undefined);
      setState(undefined);
      if (socket) {
        socket.disconnect();
      }
    }
  }, [id, socket, username]);

  const makeCall = (call: number) => {
    if (channel) {
      channel.push("make_call", {body: call});
    }
  }

  const playCard = (card: Card) => {
    if (channel) {
      channel.push("play_card", {body: card})
    }
  }

  const joinGame = (team: Team) => {
    if (channel) {
      channel.push("join_game", {body: {team, username}})
    }
  }

  return { error, state, joinGame, makeCall, playCard };
}
