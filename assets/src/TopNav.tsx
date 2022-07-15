import * as React from "react";
import { Link } from "react-router-dom";
import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";

import { selectUsername, setUsername } from "./features/user/userSlice";
import { deleteRequest, request } from "./app/client";
import { useAppDispatch } from "./app/store";

import { Button } from "./Button";
import { Navbar, NavbarSection } from "./Navbar";
import { Header, PaddedHorizontalLayout } from "./Layout";

export function TopNav() {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const username = useSelector(selectUsername);

  const onLogout = useCallback(() => {
    request(deleteRequest("/session")).then(() => {
      dispatch(setUsername(undefined));
      navigate("/");
    });
  }, [dispatch, navigate]);

  return (
    <Navbar>
      <NavbarSection>
        <Link to="/">
          <Header>Spades</Header>
        </Link>
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
