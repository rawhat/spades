import * as React from "react";
import classnames from "classnames";

type TooltipProps = React.PropsWithChildren<{
  position?: "bottom" | "left" | "right" | "top";
  text: string;
}>;

export const Tooltip = ({ children, position, text }: TooltipProps) => (
  <div
    className={classnames("tooltip", { [`tooltip-${position}`]: position })}
    //@ts-ignore
    dataTooltip={text}
  >
    {children}
  </div>
);

Tooltip.defaultProps = {
  position: "top",
};
