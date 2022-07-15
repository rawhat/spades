import * as React from "react";
import classnames from "classnames";

export const Navbar = ({ children }: React.PropsWithChildren<{}>) => (
  <header className="navbar">{children}</header>
);

type NavbarSectionProps = React.PropsWithChildren<{
  center?: boolean;
}>;

export const NavbarSection = ({ center, children }: NavbarSectionProps) => (
  <section
    className={classnames({
      "navbar-section": !center,
      "navbar-center": center,
    })}
  >
    {children}
  </section>
);
