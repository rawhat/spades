import * as React from "react";
import { Link } from "react-router-dom";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useSelector } from "react-redux";

import { RootState } from "./app/store";
import { fetchGames } from "./features/lobby/lobbySlice";

import { Columns, Column, Container, Divider, Header } from "./Layout";
import {
  Table,
  TableCell,
  TableHeader,
  TableHeaderCell,
  TableBody,
  TableRow,
} from "./Table";
import NewGame from "./NewGame";

function Lobby() {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchGames());
  }, [dispatch]);

  const games = useSelector((state: RootState) => state.lobby.games);

  return (
    <Container width="100%">
      <Columns>
        <Column width={4} margin="auto">
          <Header>Lobby</Header>
        </Column>
      </Columns>
      <Divider orientation="horizontal" />
      <Columns>
        <Column width={4} margin="auto">
          <NewGame />
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
              <TableRow key={game.id}>
                <TableCell>
                  <Link to={`/game/${game.id}`}>{game.name}</Link>
                </TableCell>
                <TableCell>{game.players}/4</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </Container>
  );
}

export default Lobby;
