import * as React from "react";
import { useMemo } from "react";
import classnames from "classnames";

interface ContainerProps {
  alignItems?: Align;
  color?: React.CSSProperties["color"];
  display?: "block" | "flex";
  flexDirection?: "row" | "column";
  flexGrow?: 0 | 1;
  height?: string | number;
  justifyContent?: Align;
  position?: "absolute" | "fixed" | "relative";
  width?: string | number;
}

export const Container: React.FC<ContainerProps> = ({
  alignItems,
  children,
  color,
  display,
  flexDirection,
  flexGrow,
  height,
  justifyContent,
  position,
  width,
}) => {
  const style = useMemo(
    () => ({
      alignItems,
      backgroundColor: color,
      display,
      flexDirection,
      flexGrow,
      height,
      justifyContent,
      position,
      width,
    }),
    [
      alignItems,
      color,
      display,
      flexDirection,
      flexGrow,
      height,
      justifyContent,
      position,
      width,
    ]
  );
  return (
    <div className="container" style={style}>
      {children}
    </div>
  );
};
Container.defaultProps = {
  display: "block",
};

export const VerticalLayout: React.FC<ContainerProps> = (props) => (
  <Container display="flex" flexDirection="column" {...props}>
    {props.children}
  </Container>
);

export const HorizontalLayout: React.FC<ContainerProps> = (props) => (
  <Container display="flex" flexDirection="row" {...props}>
    {props.children}
  </Container>
);

interface PaddedProps extends ContainerProps {
  padding: number;
}

export const PaddedVerticalLayout: React.FC<PaddedProps> = ({padding, ...props}) => {
  const style = useMemo(() => {
    return {
      paddingTop: padding,
    }
  }, [padding])
  return (
    <Container display="flex" flexDirection="column" {...props}>
      {React.Children.map(props.children, (child, i) => (
        i === 0 ? child : (
          <div style={style}>{child}</div>
        )
      ))}
    </Container>
  )
}

export const PaddedHorizontalLayout: React.FC<PaddedProps> = ({padding, ...props}) => {
  const style = useMemo(() => {
    return {
      paddingLeft: padding,
    }
  }, [padding])
  return (
    <Container display="flex" flexDirection="row" {...props}>
      {React.Children.map(props.children, (child, i) => (
        i === 0 ? child : (
          <div style={style}>{child}</div>
        )
      ))}
    </Container>
  )
}

type Align = "stretch" | "flex-start" | "flex-end" | "center" | "space-between";

interface RowsProps {
  alignItems?: Align;
  justifyContent?: Align;
}

export const Rows: React.FC<RowsProps> = ({
  alignItems,
  children,
  justifyContent,
}) => {
  const style = useMemo(
    () =>
      ({
        display: "flex",
        flexDirection: "row",
        alignItems,
        justifyContent,
      } as React.CSSProperties),
    [alignItems, justifyContent]
  );
  return <div style={style}>{children}</div>;
};
Rows.defaultProps = {
  alignItems: "center",
  justifyContent: "flex-start",
};

interface RowProps {
  height: string | number;
}

export const Row: React.FC<RowProps> = ({ children, height }) => {
  const style = useMemo(
    () => ({
      height,
    }),
    [height]
  );
  return <div style={style}>{children}</div>;
};

interface ColumnsProps {
  oneLine?: boolean;
  gapless?: boolean;
}

export const Columns: React.FC<ColumnsProps> = ({
  children,
  gapless,
  oneLine,
}) => (
  <div
    className={classnames("columns", {
      "col-gapless": gapless,
      "col-oneline": oneLine,
    })}
  >
    {children}
  </div>
);
Columns.defaultProps = {
  oneLine: false,
  gapless: false,
};

interface ColumnProps {
  margin?: "left" | "right" | "auto";
  width?: number | "xs" | "sm" | "md" | "lg" | "xl";
}

export const Column: React.FC<ColumnProps> = ({ children, margin, width }) => (
  <div
    className={classnames("column", {
      [`col-${width}`]: typeof width === "number",
      "col-mx-auto": margin === "auto",
      "col-ml-auto": margin === "left",
      "col-mr-auto": margin === "right",
      "col-xs-auto": width === "xs",
      "col-sm-auto": width === "sm",
      "col-md-auto": width === "md",
      "col-lg-auto": width === "lg",
      "col-xl-auto": width === "lg",
    })}
  >
    {children}
  </div>
);

interface DividerProps {
  center?: boolean;
  orientation?: "horizontal" | "vertical";
  text?: string;
}

export const Divider = ({ center, orientation, text }: DividerProps) => (
  <div
    className={classnames({
      "divider-vert": orientation === "vertical",
      divider: orientation === "horizontal",
      "text-center": center,
    })}
    //@ts-ignore
    datacontent={text}
  />
);

Divider.defaultProps = {
  orientation: "vertical",
};

export const Center: React.FC = ({ children }) => (
  <div className="p-centered">{children}</div>
);

export const Header: React.FC = ({ children }) => (
  <span className="h1">{children}</span>
);

export const SubHeader: React.FC = ({ children }) => (
  <span className="h3">{children}</span>
);
