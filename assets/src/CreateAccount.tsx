import * as React from 'react';
import { Link } from "react-router-dom";
import { useDispatch } from "react-redux";
import { useEffect } from "react";
import { useHistory } from "react-router-dom";
import { useState } from "react";

import { FetchArguments, postRequest } from "./app/client";
import { setUsername } from "./features/user/userSlice";
import { useQuery } from "./useQuery";

import { Button } from "./Button";
import { Columns, Column, Container, PaddedVerticalLayout } from "./Layout";
import { Panel, PanelBody, PanelHeader, PanelFooter } from "./Panel";
import { HorizontalForm, Input } from "./Form";
import { Bold } from "./Text";

function CreateAccount() {
  const history = useHistory();

  const [username, setUser] = useState("");
  const [password, setPassword] = useState("");
  const [repeatedPassword, setRepeatedPassword] = useState("");
  const [request, setRequest] = useState<FetchArguments>();

  const dispatch = useDispatch();
  const onCreate = () => {
    if (password === repeatedPassword) {
      setRequest(
        postRequest(
          '/api/user',
          {user: {username, password}}
        )
      );
    }
  }

  const {data, status: _status, error} = useQuery<
    string,
    'username' | 'password'
  >(request);

  useEffect(() => {
    if (data) {
      dispatch(setUsername(data))
    }
  }, [data, dispatch, history])

  return (
    <Container>
      <Columns>
        <Column margin="auto" width={6}>
          <Panel>
            <PanelHeader>
              <Bold>Create Account</Bold>
            </PanelHeader>
            <PanelBody>
              <HorizontalForm>
                <PaddedVerticalLayout padding={25}>
                  <Columns>
                    <Column width={4}>
                      Username
                    </Column>
                    <Column width={8}>
                      <Input
                        onChange={setUser}
                        value={username}
                      />
                    </Column>
                  </Columns>
                  <Columns>
                    <Column width={4}>
                      Password
                    </Column>
                    <Column width={8}>
                      <Input
                        error={error?.password?.toString()}
                        onChange={setPassword}
                        type="password"
                        value={password}
                      />
                    </Column>
                  </Columns>
                  <Columns>
                    <Column width={4}>
                      Repeat Password
                    </Column>
                    <Column width={8}>
                      <Input
                        onChange={setRepeatedPassword}
                        type="password"
                        value={repeatedPassword}
                      />
                    </Column>
                  </Columns>
                  <Columns>
                    <Column margin="auto">
                      <Link to="/login">
                        Already have an account?  Click here to login.
                      </Link>
                    </Column>
                  </Columns>
                  <Columns>
                    <Column margin="auto" width={3}>
                      <Button onClick={onCreate}>Create</Button>
                    </Column>
                  </Columns>
                </PaddedVerticalLayout>
              </HorizontalForm>
            </PanelBody>
            <PanelFooter />
          </Panel>
        </Column>
      </Columns>
    </Container>
  )
}

export default CreateAccount;
