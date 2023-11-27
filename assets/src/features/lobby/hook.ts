import { useState } from "react";
import { useEffect } from "react";
import { useMemo } from "react";

export interface GameResponse {
  id: string;
  name: string;
  players: number;
}

interface GameMap {
  [id: string]: GameResponse;
}

type LobbySocket = [GameResponse[], string?];

const protocol = process.env.NODE_ENV === "production" ? "wss" : "ws";

export function useLobbySocket(): LobbySocket {
  const [games, setGames] = useState<GameMap>({});
  const [error, _setError] = useState<string | undefined>(undefined);

  useEffect(() => {
    const socket = new WebSocket(
      `${protocol}://${
        process.env.NODE_ENV === "production"
          ? window.location.host
          : "localhost:5000"
      }/socket/lobby`,
    );
    console.log("got a socket", socket, socket.readyState === socket.CLOSED);

    const updateGameInfo = (games: GameResponse | GameResponse[]) =>
      Array.isArray(games)
        ? setGames((existing) =>
            games.reduce(
              (acc, game) => ({ ...acc, [game.id]: game }),
              existing,
            ),
          )
        : setGames((existing) => ({ ...existing, [games.id]: games }));

    socket.onopen = () => {
      console.log("socket opened");
    };

    socket.onmessage = ({ data }) => {
      console.log("got a message", data);
      const message: GameResponse = JSON.parse(data);
      updateGameInfo(message);
    };

    return () => {
      console.log("closing socket");
      socket.close();
    };
  }, []);

  const gamesList = useMemo(() => {
    return Object.values(games);
  }, [games]);

  return [gamesList, error];
}
