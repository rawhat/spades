const socketMiddleware = (store) => (next) => {
  return (action) => {
    next(action);
  }
}

export default socketMiddleware;
