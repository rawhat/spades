import * as React from "react";
import { Navigate } from "react-router-dom";
import { useSelector } from "react-redux";

import { selectUsername } from "./features/user/userSlice";

const Authenticated = ({ children }: React.PropsWithChildren<{}>) => {
  const username = useSelector(selectUsername);
  if (!username) {
    return <Navigate to="/" replace />;
  }
  return <>{children}</>;
};

export default Authenticated;
