import React from 'react'
import classnames from 'classnames';

interface TableProps {
  striped?: boolean;
  hover?: boolean;
}

export const Table: React.FC<TableProps> = ({children, hover, striped}) => (
  <table className={classnames('table', {hover, striped})}>
    {children}
  </table>
)

export const TableHeader: React.FC = ({children}) => (
  <thead>
    <tr>
      {children}
    </tr>
  </thead>
)

export const TableHeaderCell: React.FC = ({children}) => (
  <th>
    {children}
  </th>
)

export const TableBody: React.FC = ({children}) => (
  <tbody>
    {children}
  </tbody>
)

interface TableRowProps {
  active?: boolean;
}

export const TableRow: React.FC<TableRowProps> = ({active, children}) => (
  <tr className={classnames({active})}>
    {children}
  </tr>
)

export const TableCell: React.FC = ({children}) => (
  <td>
    {children}
  </td>
)
