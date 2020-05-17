import * as React from "react";
import classnames from "classnames";

interface ButtonProps {
  active?: boolean;
  block?: boolean;
  color?: "primary" | "link" | "success" | "error";
  disabled?: boolean;
  float?: "left" | "right";
  loading?: boolean;
  onClick: (e: React.SyntheticEvent<HTMLButtonElement>) => void;
  size?: "sm" | "lg";
}

export const Button: React.FC<ButtonProps> = ({
  active,
  block,
  children,
  color,
  disabled,
  float,
  loading,
  size,
  ...props
}) => (
  <button
    className={classnames("btn", {
      [`btn-${color}`]: color,
      [`btn-${size}`]: size,
      "btn-active": active,
      "btn-block": block,
      "btn-disabled": disabled,
      "btn-loading": loading,
      [`float-${float}`]: float,
    })}
    {...props}
  >
    {children}
  </button>
);

interface ButtonGroupProps {
  block?: boolean;
}

export const ButtonGroup: React.FC<ButtonGroupProps> = ({
  block,
  children,
}) => (
  <div className={classnames("btn-group", { "btn-group-block": block })}>
    {children}
  </div>
);
