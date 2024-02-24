import * as React from "react";
import { Link } from "react-router-dom";

import { useLobbySocket } from "./features/lobby/hook";

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
import { Toast } from "./Toast";

function Lobby() {
  const [games, error] = useLobbySocket();

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
      {error && (
        <Columns>
          <Column width={6} margin="auto">
            <Toast color="error">{error}</Toast>
          </Column>
        </Columns>
      )}
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
