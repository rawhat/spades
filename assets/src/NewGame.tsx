import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useHistory } from "react-router-dom";
import { useState } from "react";

import { createGame } from "./features/lobby/lobbySlice";

import { Button } from "./Button";
import { Input } from "./Form";
import { PaddedHorizontalLayout } from "./Layout";

function NewGame() {
  const dispatch = useDispatch();
  const history = useHistory();

  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");

  const newGame = useCallback(() => {
    dispatch(createGame(name, history));
  }, [dispatch, history, name]);

  const close = useCallback(() => {
    setOpen(false);
    setName("");
  }, [])

  return ( 
    <>
      {open ? (
        <PaddedHorizontalLayout padding={10}>
          <Input
            onChange={setName}
            placeholder="Enter game name..."
            value={name}
          />
          <Button color="success" onClick={newGame}>Create</Button>
          <Button color="error" onClick={close}>Cancel</Button>
        </PaddedHorizontalLayout>
      ) : (
        <Button color="success" onClick={() => setOpen(true)}>
          New Game
        </Button>
      )}
    </>
  )
}

export default NewGame;