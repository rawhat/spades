import React from 'react';
import classnames from 'classnames';

interface TooltipProps extends React.FC {
  position?: "bottom" | "left" | "right" | "top";
  text: string;
}

export const Tooltip: React.FC<TooltipProps> = ({children, position, text}) => (
  <div
    className={
      classnames("tooltip", {[`tooltip-${position}`]: position})
    }
    //@ts-ignore
    dataTooltip={text}
  >
    {children}
  </div>
)

Tooltip.defaultProps = {
  position: "top",
}
