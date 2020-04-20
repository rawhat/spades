import * as React from "react";
import { useSelector } from "react-redux";

import { selectUsername } from "./features/user/userSlice";

import { Navbar, NavbarSection } from "./Navbar";
import { Header } from "./Layout";

function TopNav() {
  const username = useSelector(selectUsername);
  return (
    <Navbar>
      <NavbarSection>
        <Header>Spades</Header>
      </NavbarSection>
      {username && <NavbarSection>Welcome, {username}</NavbarSection>}
    </Navbar>
  );
}

export default TopNav;
