import React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useHistory } from "react-router-dom";
import { useState } from "react";

import { setUsername } from "./features/user/userSlice";

import { Button } from "./Button";
import {
  Columns,
  Column,
  Container,
} from "./Layout";
import {
  HorizontalForm,
  Input,
} from "./Form";

function Home() {
  const [name, setName] = useState("");
  const dispatch = useDispatch();
  const history = useHistory();

  const onNameChange = useCallback(
    setName,
    [setName]
  );

  const onJoin = useCallback(() => {
    dispatch(setUsername(name));
    history.push("/lobby");
  }, [dispatch, history, name]);

  return (
    <Container>
      <Columns>
        <Column width={12}>
          <Container height={250} />
        </Column>
      </Columns>
      <HorizontalForm>
        <Columns>
          <Column margin="left" width={6}>
            <Input
              placeholder="Choose a name"
              onChange={onNameChange}
              value={name}
            />
          </Column>
          <Column width={3}>
            <Button onClick={onJoin}>Join</Button>
          </Column>
        </Columns>
      </HorizontalForm>
    </Container>
  );
}

export default Home;
