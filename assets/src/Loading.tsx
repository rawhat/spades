import * as React from "react";
import classnames from "classnames";

interface LoadingProps {
  size?: "lg";
}

export const Loading = ({ size }: LoadingProps) => (
  <div className={classnames("loading", { [`loading-${size}`]: size })} />
);
