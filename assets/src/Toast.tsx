import * as React from "react";
import classnames from "classnames";

type ToastProps = React.PropsWithChildren<{
  color?: "primary" | "success" | "warning" | "error";
}>

export const Toast = ({ children, color }: ToastProps) => (
  <div className={classnames("toast", { [`toast-${color}`]: color })}>
    {children}
  </div>
);
