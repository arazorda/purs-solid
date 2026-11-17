# Design

## Scope

purs-solid adds type-checked bindings to the public APIs of `solid-js`, `@solidjs/web`, `@solidjs/router`, `@solidjs/meta` and `@solidjs/vite-plugin` start mode.

Runtime logic lives in JS FFI that calls Solid; PureScript supplies the types (rows, instance chains, type-level parsing) and thin calls. PureScript values take the shape Solid expects, so the FFI passes them straight through:

- Options are records with optional fields. The bindings pass through Solid options and translate PureScript-specific values, such as async serialization codecs.
- No ADT → string → JS round trips, and no PureScript ADTs or interpreters on hot paths where a JS check does the job.
- Plain DOM access uses registry bindings (`web-html`, `web-dom`, …).

The runtime renderer delegates SSR and hydration to `dynamic(() => tag, { static: true })`. In the browser it clones one `template` per subtree shape, applies props with `assign` or `spread`, and inserts the remaining children. After assigning static props to anchors or forms, it calls Solid's `claimElement` so the router sees them. The runtime renderer and Vite wrapper attach case-sensitive `on:name` listeners through refs.

In Vite builds (unless `compileViews: false`), `vite/compile.mjs` rewrites element calls in purs or purs-backend-es output into JSX and hands it to Solid's compiler, so Solid owns templates, SSR and hydration there too. It decodes each field from the element's props dictionary by the instance names in `Solid.Internal.Props`, and keeps the field's runtime meaning (the library's own converters, or the field's runtime entry). An element it can't read (props or children that aren't literal) stays a runtime call, and the two mix in one tree. `test:compiled` checks that both paths give the same DOM, server HTML and hydration.

## Rules

1. **Derived values are pure and writes are effects.** `Accessor` is a lawful `Monad`. Effects split into a tracked computation (`Accessor a` or `Async a`) and an untracked apply step.
2. **Owned code runs in `Setup`**, a newtype over `Effect`. `set`, `modify`, `refresh` and `get` run in `Effect`. In `Setup`, use `sample` for an initial value and `liftSetup` for external effects. `createSignal` and `createRoot` work in both through the sealed `MonadReactive` class.
3. **Async is part of the graph.** `createAsync :: Accessor (Aff a) -> Setup (Async a /\ Refresh a)` cancels superseded fibers. Render or derive from an `Async`, or await it with `resolve`. Supplying `loadingValue` gives an `Accessor`. Async projections are `AsyncStore`s, whose values read as `Async`. Optimistic writes run inside an `Action` or a router action's `onSubmit` hook.
4. **Passing a prop isn't reading it.** Props are plain records; reactive fields are `Accessor a`.
5. **JSX is a description.** Parents and control flow realize a view when they need it. Hydration expects the same tree on both sides. Use `clientOnly` for a view that requires the browser.
6. **Stores are updated with typed paths and pure `Update` values**, applied to Solid's draft in the FFI. Non-structural values are frozen before entering a store (`StoreValue`), because Solid 2 proxies class instances and PureScript ADTs are class instances.
7. **Typed DOM.** Element props are records checked field by field against the element's `dom-indexed` row; every attribute accepts a value or an `Accessor`.
8. **Data crossing server and client is `Serializable`** (primitives, `Nullable`, arrays, records) or goes through an explicit codec.

## FFI rules

- Never import compiled PureScript output from FFI: it breaks under `purs-backend-es`. Build `Maybe` / `Either` on the PureScript side; pass `Nullable` or continuations.
- Use `EffectFn` / `Fn` on hot paths.
- Guard every place Solid overloads on `typeof x === "function"` (signal values, setter arguments, store values, children): PureScript functions are JS functions.
- Errors are `Effect.Exception.Error`.

## Solid 2 behaviour this relies on

- A store keeps an element's proxy (and so its row) across `reconcile` only while something reads that element's fields.
- `purs-solid/vite` adds `"use server"` to compiled modules that re-export `useServer`. Solid's compiler emits references for the client while keeping the implementation on the server. For purs-backend-es output, the wrapper reads the module's public exports from CoreFn.
- Solid's `start.app` and `start.middleware` must be files inside the Vite root with a default export, so the wrapper writes one-line re-exports to `node_modules/.purs-solid/`.
- The middleware adapter receives Solid's request event. The PureScript continuation accepts the request to forward, updates the event, and calls Solid's zero-argument `next()`.
- Server-side `lazy` finds a module's client chunk (to preload it before hydration) through a `$$moduleUrl` export that Solid's JSX transform adds to JSX modules; the wrapper adds it to compiled modules for the server.
- `purs` rewrites a burst of output files per build. In dev the wrapper replaces Vite's per-file updates for compiled output with one reload once the burst settles: the server's modules first, then the browser. Otherwise a page can render on half-updated modules or hydrate against the other version.
- With `renderToStringWithHead`, Solid delivers the title as a script that sets `document.title`.
- The npm manifest records the toolchain tested by this repository. The Git-hosted `v0.1.0` wrapper declares exact Vite and Solid Vite plugin peer versions.

## Not bound

- `merge` / `omit`: props are records.
- `createTrackedEffect` (deprecated, breaks rule 1); `createErrorBoundary` / `createLoadingBoundary` / `createRevealOrder` (the control-flow functions cover them).
- `storePath` (typed paths replace it); `defineRoute(s)` / `Router.paths` (`route @path` and `href` replace them).
- Internal and dev exports (`enableExternalSource`, `flatten`, `getObserver`, `$TRACK`, `DEV` / `OBSERVE`).
- `ssrSource` on sync memos, `"hybrid"`, `mapArray`'s `fallback` / `name` (the `*Else` functions cover fallbacks), serializer `plugins`, asset `manifest`, `enableRichArguments`, `live` / `GET`.
