import * as React from "react";
//import classnames from 'classnames';

export const Panel = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel">{children}</div>
);

export const PanelHeader = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel-header">{children}</div>
);

export const PanelTitle = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel-title">{children}</div>
);

export const PanelNav = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel-nav">{children}</div>
);

export const PanelBody = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel-body">{children}</div>
);

export const PanelFooter = ({ children }: React.PropsWithChildren<{}>) => (
  <div className="panel-footer">{children}</div>
);
