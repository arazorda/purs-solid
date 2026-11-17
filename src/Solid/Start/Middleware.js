export const middlewareImpl = (handler) => (event, next) =>
  handler(event)((request) => () => {
    event.request = request;
    return next();
  })();
