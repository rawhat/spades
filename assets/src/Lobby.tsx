import React from "react";
import { Link } from "react-router-dom";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useSelector } from "react-redux";

import { RootState } from "./app/store";
import { fetchGames } from "./features/lobby/lobbySlice";
import { createGame } from "./features/lobby/lobbySlice";

function Lobby() {
  const dispatch = useDispatch();
  const history = useHistory();

  useEffect(() => {
    dispatch(fetchGames());
  }, [dispatch]);

  const games = useSelector((state: RootState) => state.lobby.games);

  const newGame = useCallback(() => {
    dispatch(createGame(history));
  }, [dispatch, history]);

  return (
    <div>
      <div>welcome to the lobby.</div>
      <button onClick={newGame}>New Game</button>
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
