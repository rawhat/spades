import { Create, Home, Lobby, Login, Game, NotFound } from "./spades_ui.mjs";

export function setupRouter(dispatch) {
  document.addEventListener("click", (e) => {
    let target = e.target;

    while (target) {
      if (target === document.body) return;
      if (target.tagName === "A") {
        const url = new URL(target.href);
        if (url.origin !== window.location.origin) return;
        const route = new Route(url.pathname, url.hash);

        e.preventDefault();
        window.requestAnimationFrame(() => {
          window.history.pushState({}, "", url.href);
          if (url.pathname === window.location.pathname && url.hash) {
            document.querySelector(url.hash)?.scrollIntoView();
          } else {
            window.scrollTo(0, 0);
          }
        });
        return void dispatch(route);
      }

      target = target.parentNode;
    }
  });

  window.addEventListener("popstate", () => {
    const url = new URL(window.location.href);
    const route = new Route(url.pathname, url.hash);

    dispatch(route);
  });
}

export function getInitialRoute() {
  const { pathname } = new URL(window.location.href);
  switch (pathname) {
    case "/": return new Home();
    case "/login": return new Login();
    case "/create": return new Create();
    case "/lobby": return new Lobby();
    default: {
      const gameAndId = pathname.match(/^\/game\/(\d+)$/);
      if (gameAndId) {
        return new Game(gameAndId[0]);
      }
      return new NotFound(pathname);
    }
  }
}

export function getHostnameAndPort() {
  return [window.location.hostname, window.location.port]
}
