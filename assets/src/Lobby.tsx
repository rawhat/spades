import React from "react";
import { Link } from "react-router-dom";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useSelector } from "react-redux";

import { RootState } from "./app/store";
import { fetchGames } from "./features/lobby/lobbySlice";

function Lobby() {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchGames());
  }, [dispatch]);

  const games = useSelector((state: RootState) => state.lobby.games);

  return (
    <div>
      <div>welcome to the lobby.</div>
      <ul>
        {games.map((game) => (
          <li key={game}>
            <Link to={`/game/${game}`}>{game}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default Lobby;
