import * as React from "react";
import classnames from "classnames";

interface ToastProps {
  color?: "primary" | "success" | "warning" | "error";
}

export const Toast: React.FC<ToastProps> = ({ children, color }) => (
  <div className={classnames("toast", { [`toast-${color}`]: color })}>
    {children}
  </div>
);
