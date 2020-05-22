import { Socket } from "phoenix";
import { useState } from "react";
import { useEffect } from "react";
import { useMemo } from "react";

export interface GameResponse {
  id: string;
  name: string;
  players: number;
};

interface GameMap {[id: string]: GameResponse}

type LobbySocket = [GameResponse[], string?];

export function useLobbySocket(): LobbySocket {
  const [games, setGames] = useState<GameMap>({});
  const [error, setError] = useState<string | undefined>(undefined);

  useEffect(() => {
    const socket = new Socket("/socket/lobby");
    socket.connect();
    const channel = socket.channel('lobby:*');

    const setGameList = (games: GameResponse[]) => {
      setGames(games.reduce((acc, game) => {
        acc[game.id] = game;
        return acc;
      }, {} as GameMap))
    }

    channel
      .join()
      .receive("ok", (data: {games: GameResponse[]}) => {
        setGameList(data.games);
      })
      .receive("err", (err: any) => {
        setError(`Error connecting to lobby socket: ${JSON.stringify(err)}`);
      })

    channel.on("list_games", setGameList)
    channel.on("update_game", (game: GameResponse) => {
      setGames(existing => ({...existing, [game.id]: game}))
    })

    return () => {
      channel.leave();
    }
  }, [])

  const gamesList = useMemo(() => {
    return Object.values(games);
  }, [games])

  return [gamesList, error];
}
