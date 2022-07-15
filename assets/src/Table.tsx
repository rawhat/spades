import * as React from "react";
import classnames from "classnames";

type TableProps = React.PropsWithChildren<{
  striped?: boolean;
  hover?: boolean;
}>;

export const Table = ({ children, hover, striped }: TableProps) => (
  <table className={classnames("table", { hover, striped })}>{children}</table>
);

export const TableHeader = ({ children }: React.PropsWithChildren<{}>) => (
  <thead>
    <tr>{children}</tr>
  </thead>
);

export const TableHeaderCell = ({ children }: React.PropsWithChildren<{}>) => (
  <th>{children}</th>
);

export const TableBody = ({ children }: React.PropsWithChildren<{}>) => (
  <tbody>{children}</tbody>
);

type TableRowProps = React.PropsWithChildren<{
  active?: boolean;
}>;

export const TableRow = ({ active, children }: TableRowProps) => (
  <tr className={classnames({ active })}>{children}</tr>
);

export const TableCell = ({ children }: React.PropsWithChildren<{}>) => (
  <td>{children}</td>
);
