import * as React from "react";
//import classnames from 'classnames';

export const Panel: React.FC = ({ children }) => (
  <div className="panel">{children}</div>
);

export const PanelHeader: React.FC = ({ children }) => (
  <div className="panel-header">{children}</div>
);

export const PanelTitle: React.FC = ({ children }) => (
  <div className="panel-title">{children}</div>
);

export const PanelNav: React.FC = ({ children }) => (
  <div className="panel-nav">{children}</div>
);

export const PanelBody: React.FC = ({ children }) => (
  <div className="panel-body">{children}</div>
);

export const PanelFooter: React.FC = ({ children }) => (
  <div className="panel-footer">{children}</div>
);
