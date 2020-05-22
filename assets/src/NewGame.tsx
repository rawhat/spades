import * as React from "react";
import { useCallback } from "react";
import { useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useState } from "react";

import { FetchArguments, Progress, postRequest } from "./app/client";
import { GameResponse } from "./features/lobby/hook";
import { useQuery } from "./useQuery";

import { Button } from "./Button";
import { Input } from "./Form";
import { PaddedHorizontalLayout } from "./Layout";

function NewGame() {
  const history = useHistory();

  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");

  const [request, setRequest] = useState<FetchArguments>();

  const { data, status, error } = useQuery<
    GameResponse,
    "name"
  >(request);

  const newGame = useCallback(() => {
    setRequest(postRequest("/api/game", { name }))
  }, [name]);

  const close = useCallback(() => {
    setOpen(false);
    setName("");
  }, []);

  useEffect(() => {
    if (data) {
      history.push(`/game/${data.id}`)
    }
  }, [data, history])

  return (
    <>
      {open ? (
        <PaddedHorizontalLayout padding={10}>
          <Input
            error={error?.name.join(', ')}
            onChange={setName}
            placeholder="Enter game name..."
            value={name}
          />
          <Button
            color="success"
            loading={status === Progress.Loading}
            onClick={newGame}
          >
            Create
          </Button>
          <Button
            color="error"
            loading={status === Progress.Loading}
            onClick={close}
          >
            Cancel
          </Button>
        </PaddedHorizontalLayout>
      ) : (
        <Button color="success" onClick={() => setOpen(true)}>
          New Game
        </Button>
      )}
    </>
  );
}

export default NewGame;
