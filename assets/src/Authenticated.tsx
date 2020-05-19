import * as React from "react";
import { Redirect } from "react-router-dom";
import { Route } from "react-router-dom";
import { RouteProps } from "react-router-dom";
import { useSelector } from "react-redux";

import { selectUsername } from "./features/user/userSlice";

const Authenticated: React.FC<RouteProps> = ({ children, ...rest }) => {
  const username = useSelector(selectUsername);
  return (
    <Route
      {...rest}
      render={({ location }) =>
        username ? (
          children
        ) : (
          <Redirect to={{ pathname: "/", state: { from: location } }} />
        )
      }
    />
  );
};

export default Authenticated;
