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

import { Button } from "./Button";
import {
  Columns,
  Column,
  Container,
  Divider,
  Header
} from "./Layout";
import {
  Table,
  TableCell,
  TableHeader,
  TableHeaderCell,
  TableBody,
  TableRow
} from "./Table";

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
    <Container width="100%">
      <Columns>
        <Column width={2} margin="auto">
          <Header>Lobby</Header>
        </Column>
      </Columns>
      <Divider orientation="horizontal" />
      <Columns>
        <Column width={2} margin="auto">
          <Button color="success" onClick={newGame}>New Game</Button>
        </Column>
      </Columns>
      {games.length > 0 && (
        <Table>
          <TableHeader>
            <TableHeaderCell>Game</TableHeaderCell>
            <TableHeaderCell>Players</TableHeaderCell>
          </TableHeader>
          <TableBody>
            {games.map((game) => (
              <TableRow key={game}>
                <TableCell>
                  <Link to={`/game/${game}`}>
                    {game}
                  </Link>
                </TableCell>
                <TableCell>
                  ???
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </Container>
  );
}

export default Lobby;
