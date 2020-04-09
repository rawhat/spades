import React from 'react'
import { useSelector } from 'react-redux';

import { selectUsername } from "./features/user/userSlice";

import {
  Navbar,
  NavbarSection
} from './Navbar';

function TopNav() {
  const username = useSelector(selectUsername);
  return (
    <Navbar>
      <NavbarSection>
        Spades
      </NavbarSection>
      {username && (
        <NavbarSection>
          Welcome, {username}
        </NavbarSection>
      )}
    </Navbar>
  )
}

export default TopNav;
