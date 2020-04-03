import React from "react";
//import { AnyAction } from "redux";
//import { Dispatch } from "redux";
import { useContext } from "react";
import { useEffect } from "react";
import { useState } from "react";

//import { Store } from "../../app/store";
import { Card } from "./features/game/gameSlice";
import { GameStatus } from "./features/game/gameSlice";
import { PlayerStatus } from "./features/game/gameSlice";
import { getPlayerState } from "./features/game/gameSlice";

export const SocketProvider = React.createContext(null);

export const useSocket = () => useContext(SocketProvider);

export const useGameState = (id?: string, username?: string) => {
  const [socket, setSocket] = useState<WebSocket>();
  const [state, setState] = useState<GameStatus | PlayerStatus>();

  useEffect(() => {
    if (id && !socket) {
      const socket = new WebSocket(`/game/${id}/socket`);
      socket.onmessage = onMessage;
      socket.onopen = onOpen;
      setSocket(socket);
    }
    return () => {
      setSocket(null);
    }
  }, [id, socket]);

  const onOpen = () => {
  }

  const onMessage = (message) => {
    console.log("got message")
  }

  const makeCall = (call: number) => {
  }

  const playCard = (card: Card) => {
  }

  return { state, makeCall, playCard };
}
