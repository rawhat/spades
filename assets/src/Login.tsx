import * as React from 'react';
import { Link } from "react-router-dom";
import { useDispatch } from 'react-redux';
import { useState } from "react";

import { login } from "./features/user/userSlice";

import { Button } from "./Button";
import { Columns, Column, Container, PaddedVerticalLayout } from "./Layout";
import { Panel, PanelBody, PanelHeader, PanelFooter } from "./Panel";
import { HorizontalForm, Input } from "./Form";
import { Bold } from "./Text";

function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const dispatch = useDispatch();
  const onLogin = () => dispatch(login(username, password));

  return (
    <Container>
      <Columns>
        <Column width={6} margin="auto">
          <Panel>
            <PanelHeader>
              <Bold>Login</Bold>
            </PanelHeader>
            <PanelBody>
              <HorizontalForm>
                <PaddedVerticalLayout padding={25}>
                  <Columns>
                    <Column margin="left" width={3}>
                      Username
                    </Column>
                    <Column margin="left" width={6}>
                      <Input
                        onChange={setUsername}
                        value={username}
                      />
                    </Column>
                  </Columns>
                  <Columns>
                    <Column margin="left" width={3}>
                      Password
                    </Column>
                    <Column margin="left" width={6}>
                      <Input
                        onChange={setPassword}
                        type="password"
                        value={password}
                      />
                    </Column>
                  </Columns>
                  <Columns>
                    <Column margin="auto">
                      <Link to="/create_user">
                        Don't have an account?  Click here to create one.
                      </Link>
                    </Column>
                  </Columns>
                  <Columns>
                    <Column margin="auto" width={3}>
                      <Button onClick={onLogin}>Login</Button>
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

export default Login;
