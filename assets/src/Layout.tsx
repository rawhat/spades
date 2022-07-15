import * as React from "react";
import { useMemo } from "react";
import classnames from "classnames";

interface ContainerProps extends React.CSSProperties {
  children?: React.ReactNode;
}

export const Container: React.FC<ContainerProps> = (props) => {
  return (
    <div className="container" style={props}>
      {props.children}
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

export const PaddedVerticalLayout: React.FC<PaddedProps> = ({
  padding,
  ...props
}) => {
  const style = useMemo(() => {
    return {
      paddingTop: padding,
    };
  }, [padding]);
  return (
    <Container display="flex" flexDirection="column" {...props}>
      {React.Children.map(props.children, (child, i) =>
        i === 0 ? child : <div style={style}>{child}</div>
      )}
    </Container>
  );
};

export const PaddedHorizontalLayout: React.FC<PaddedProps> = ({
  padding,
  ...props
}) => {
  const style = useMemo(() => {
    return {
      paddingLeft: padding,
    };
  }, [padding]);
  return (
    <Container display="flex" flexDirection="row" {...props}>
      {React.Children.map(props.children, (child, i) =>
        i === 0 ? child : <div style={style}>{child}</div>
      )}
    </Container>
  );
};

type Align = "stretch" | "flex-start" | "flex-end" | "center" | "space-between";

type RowsProps = React.PropsWithChildren<{
  alignItems?: Align;
  justifyContent?: Align;
}>

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

type RowProps = React.PropsWithChildren<{
  height: string | number;
}>

export const Row: React.FC<RowProps> = ({ children, height }) => {
  const style = useMemo(
    () => ({
      height,
    }),
    [height]
  );
  return <div style={style}>{children}</div>;
};

type ColumnsProps = React.PropsWithChildren<{
  oneLine?: boolean;
  gapless?: boolean;
}>

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

type ColumnProps = React.PropsWithChildren<{
  lg?: number | "auto";
  margin?: "left" | "right" | "auto";
  md?: number | "auto";
  sm?: number | "auto";
  width?: number;
  xl?: number | "auto";
  xs?: number | "auto";
}>

export const Column: React.FC<ColumnProps> = ({
  children,
  margin,
  width,
  xs,
  sm,
  md,
  lg,
  xl,
}) => {
  return (
    <div
      className={classnames("column", {
        [`col-${width}`]: typeof width === "number",
        "col-mx-auto": margin === "auto",
        "col-ml-auto": margin === "left",
        "col-mr-auto": margin === "right",

        [`col-xs-${xs}`]: typeof xs === "number",
        [`col-sm-${sm}`]: typeof sm === "number",
        [`col-md-${md}`]: typeof md === "number",
        [`col-lg-${lg}`]: typeof lg === "number",
        [`col-xl-${xl}`]: typeof xl === "number",
      })}
    >
      {children}
    </div>
  );
};

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

export const Center = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="p-centered">{children}</div>
);

export const Header = ({ children }: React.PropsWithChildren<{}>) => (
  <span className="h1">{children}</span>
);

export const SubHeader = ({ children }: React.PropsWithChildren<{}>) => (
  <span className="h3">{children}</span>
);
