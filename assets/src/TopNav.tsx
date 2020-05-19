import * as React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useHistory } from "react-router-dom";
import { useSelector } from "react-redux";

import { selectUsername, setUsername } from "./features/user/userSlice";
import { deleteRequest, request } from "./app/client";

import { Button } from "./Button";
import { Navbar, NavbarSection } from "./Navbar";
import { Header, PaddedHorizontalLayout } from "./Layout";

function TopNav() {
  const dispatch = useDispatch();
  const history = useHistory();
  const username = useSelector(selectUsername);

  const onLogout = useCallback(() => {
    request(deleteRequest("/session")).then(() => {
      dispatch(setUsername(undefined));
      history.push("/");
    });
  }, [dispatch, history]);

  return (
    <Navbar>
      <NavbarSection>
        <Header>Spades</Header>
      </NavbarSection>
      {username && (
        <NavbarSection>
          <PaddedHorizontalLayout
            alignItems="center"
            justifyContent="flex-end"
            padding={10}
          >
            <>Welcome, {username}</>
            <Button onClick={onLogout}>Logout</Button>
          </PaddedHorizontalLayout>
        </NavbarSection>
      )}
    </Navbar>
  );
}

export default TopNav;
