import React from 'react';
import classnames from 'classnames';

export const Navbar: React.FC = ({children}) => (
  <header className="navbar">
    {children}
  </header>
)

interface NavbarSectionProps {
  center?: boolean;
}

export const NavbarSection: React.FC<NavbarSectionProps> = ({
  center,
  children
}) => (
  <section
    className={classnames({
      'navbar-section': !center,
      'navbar-center': center
    })}
  >
    {children}
  </section>
)
