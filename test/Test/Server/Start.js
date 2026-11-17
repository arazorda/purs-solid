import { createRequestEvent, isResponseEnvelope } from "@solidjs/web";
import { provideRequestEvent } from "@solidjs/web/storage";

export const newRequest = (url) => (cookie) => () =>
  new Request(url, cookie === "" ? {} : { headers: { cookie } });

export const textResponse = (body) => () => new Response(body);

export const responseHeader = (name) => (response) => () => response.headers.get(name) ?? "";

export const setHeader = (name) => (value) => (response) => () => {
  response.headers.set(name, value);
};

export const runMiddleware = (middleware) => (request) => () => {
  const event = createRequestEvent(request);
  return provideRequestEvent(event, () =>
    middleware(event, async (...args) => {
      if (args.length !== 0) throw new Error("Start middleware next() takes no arguments");
      return new Response(`ok ${event.request.url}`);
    })
  );
};

export const responseText = (response) => () => response.text();

export const replyInfo = (value) => {
  if (value instanceof Response) {
    return {
      status: value.status,
      location: value.headers.get("location") ?? "",
      revalidate: value.headers.get("x-revalidate") ?? "",
      value: isResponseEnvelope(value) ? value.value : null,
    };
  }
  return { status: 0, location: "", revalidate: "", value };
};

export const withRequestEventImpl = (request) => (action) => () => {
  const event = createRequestEvent(request);
  const result = provideRequestEvent(event, () => action());
  return {
    result,
    status: event.response.status ?? 200,
    headers: event.response.headers.getSetCookie(),
    trace: event.response.headers.get("x-trace") ?? "",
  };
};
