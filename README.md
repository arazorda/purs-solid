# purs-solid

PureScript bindings for [Solid 2.0](https://github.com/solidjs/solid): fine-grained reactivity, rendering, SSR and hydration, the router, head tags and start mode.

The bindings use Solid's public APIs. Components create reactive state in `Setup`, and event handlers write it in `Effect`. The compiler checks props against each element and derives route parameter types from the path. See [design notes](docs/design.md).

[Guide](https://purs-solid.vercel.app/docs/) · [API reference on Pursuit](https://pursuit.purescript.org/packages/purescript-purs-solid/0.1.0)

## Example

```purescript
module Example where

import Prelude

import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Solid.Component as Component
import Solid.DOM.HTML as H
import Solid.Reactivity (createMemo)
import Solid.Signal (createSignal, modify_)
import Solid.Web (mount)

counter :: Component.Component {}
counter = Component.component \_ -> do
  count /\ setCount <- createSignal 0
  doubled <- createMemo ((_ * 2) <$> count)
  pure $ H.div { class: "counter" }
    [ H.button { onClick: \_ -> modify_ setCount (_ + 1), class: { big: (_ > 3) <$> count } } "+"
    , H.span {} (show <$> doubled)
    ]

main :: Effect Unit
main = mount (Component.element counter {})
```

## Modules

- **Reactivity:**
  - `Solid.Signal`, `Solid.Reactivity`;
  - `Solid.Setup` (the monad for component bodies and roots);
  - `Solid.Root`, `Solid.Owner`, `Solid.Lifecycle`, `Solid.Context`, `Solid.Utility`.
- **Async:**
  - `Solid.Async` (`createAsync` over `Aff`; the result is `Async`, which can't be read before it loads);
  - `Solid.Action` (transactional mutations and optimistic values).
- **Stores:** `Solid.Store` (typed paths, pure updates, projections, `createSelector`).
- **Views:**
  - `Solid.JSX`, `Solid.Component`;
  - `Solid.Component.JS` (use JavaScript Solid components);
  - `Solid.Control` (conditionals, `caseOn` for data types, lists, `loading`, `errored`, portals);
  - `Solid.DOM` (props records: `ref`, `class` toggles, `style`, `bindValue`, typed `aria-*` and `role`, `data-*`, `on:` events), `Solid.DOM.HTML`, `Solid.DOM.SVG`, `Solid.DOM.Aria`. The HTML and SVG modules are generated from `dom-indexed` by `npm run gen:dom`.
- **Rendering:** `Solid.Web` (`mount`, render, hydrate), `Solid.Web.SSR` (string, async and streamed server rendering), `Solid.Errors` (client and server error hooks, safe errors).
- **Routing and head tags:**
  - `Solid.Router` (`route @"/users/:id"` gives the component `params :: Accessor { id :: String }`, and `:id<int>` makes `id` an `Int`);
  - `Solid.Router.Path` (`href`);
  - `Solid.Router.Search` (query params typed by a schema row);
  - `Solid.Router.Query` (cached route data);
  - `Solid.Router.Action` (mutations the router tracks: forms, submissions, revalidation);
  - `Solid.Meta`.
- **Testing:** `Solid.Testing` (mount into a DOM, settle, query, click, type, collect Solid's diagnostics).
- **Start mode:** `Solid.Start.ServerFunction`, `Solid.Start.UseServer`, `Solid.Start.RequestEvent`, `Solid.Start.Response` (status, headers, and the `Reply` of an action: redirect, reload, respond), `Solid.Start.Middleware`.

## Installing

```bash
spago install purs-solid
```

For a package set that predates the release, add `purs-solid: 0.1.0` under `workspace.extraPackages` in `spago.yaml`, then run the same command.

Use Node.js 22.12 or later. Install the Solid 2 runtime and web renderer.

```bash
npm install solid-js@2 @solidjs/web@2
```

Install Router and Meta when using `Solid.Router` and `Solid.Meta`.

```bash
npm install @solidjs/router@2 @solidjs/meta@2
```

For compiled views or start mode, install the Git-hosted `purs-solid/vite` wrapper with the Vite and Solid plugin versions required by its `v0.1.0` tag.

```bash
npm install --save-dev @solidjs/vite-plugin@3.0.0 vite@8.3.8 "git+https://github.com/arazorda/purs-solid.git#v0.1.0"
```

Commit `package-lock.json` and use `npm ci` for repeatable installs. Bundle development builds with the `development` export condition to get Solid's diagnostics.

## Start mode

Export an `app` component from the PureScript module `App` and run `spago build` before starting Vite. The wrapper takes Solid's Vite options and accepts PureScript module names for `start.app` and `start.middleware`. A middleware module exports `middleware :: MiddlewareFn`. The wrapper compiles eligible views to Solid templates. Set `compileViews: false` to render every view through the runtime.

```js
import { defineConfig } from "vite";
import solid from "purs-solid/vite";

export default defineConfig({ plugins: [solid({ start: true, ssr: true })] });
```

Write server functions in a module that re-exports `Solid.Start.UseServer`. The Vite wrapper keeps the implementation on the server. Export functions defined with `serverFunction` and use `Serializable` arguments and results.

```purescript
module App.Api (module Solid.Start.UseServer, greet) where

import Prelude
import Solid.Start.ServerFunction (ServerFunction, serverFunction)
import Solid.Start.UseServer (useServer)

greet :: ServerFunction String String
greet = serverFunction \name -> pure ("Hello, " <> name)
```

Use `call` to invoke a server function in `Aff`, `queryServer` to turn a read into a cached router query, and `serverAction` to wrap a mutation that returns a `Reply`.

The example hosts enable `start.nodeServer` to generate a Node server. See [StartMode](examples/src/StartMode/Host) and [HackerNews](examples/src/HackerNews/Host).

## Examples

The `examples` workspace package holds:

- `Counter`, `TodoMVC`: client-side apps;
- `Hydration`: server rendering and hydration;
- `StartMode`: the smallest full-stack app;
- `HackerNews`: typed routes, cached server queries and streamed SSR;
- `Bench`: the rows benchmark.

```bash
npm run build:example:hackernews
```

```bash
PORT=3000 npm run start:example:hackernews
```

## Development

Requires Node.js 22.12+. PureScript, Spago and purs-tidy are pinned dev dependencies.

```bash
npm ci
npx playwright install chromium
```

```bash
npm run test:all
```

| Script | What it runs |
|---|---|
| `npm test` | client specs (happy-dom) and server specs on Solid's dev build with checks for unexpected warnings and errors |
| `npm run test:purescript:es` | the same specs compiled with `purs-backend-es` |
| `npm run test:browser-smoke` | Counter and TodoMVC in Chromium |
| `npm run test:hydration` | server render in Node, hydration in Chromium |
| `npm run test:start`, `npm run test:dev` | the start-mode example built with Vite, and under Vite dev with edits while it runs |
| `npm run test:vite` | the `purs-solid/vite` plugin's own logic |
| `npm run test:types` | props the type checker must accept or reject |
| `npm run test:compiled` | a fixture with every field kind, from purs and purs-backend-es output, through the runtime path and through compiled templates (`vite/compile.mjs`): the same server HTML, hydration that claims every element, and the same DOM after each interaction |
| `npm run test:apps:runtime` | the start-mode and dev suites with `compileViews: false` |
| `npm run build:site` | the landing page, guide and API reference (`site/`) into `site/dist`; its code samples are compiled regions of `site/src` |
| `npm run gen:dom` | regenerates `Solid.DOM.HTML`, `Solid.DOM.SVG` and `Solid.Internal.Names` |
| `npm run format`, `npm run format:check` | purs-tidy over the library, tests, examples and site |
| `npm run bench`, `npm run bench -- --compiled`, `npm run bench:reference` | the rows benchmark with the runtime renderer, compiled views, and plain Solid JSX |

## Performance

The keyed rows benchmark runs [the PureScript example](examples/src/Bench/Rows.purs) and [its Solid JSX counterpart](test/bench/reference/rows.jsx) on the same workload. These medians are from three runs per variant on an Apple M4 Pro with headless Chromium 145 and Solid 2.0.0.

| Operation | Solid JSX | purs-solid (Vite plugin) | purs-solid, runtime path |
|---|---|---|---|
| create 1k rows | 12.45 ms | 12.60 ms | 17.50 ms |
| replace 1k rows | 14.00 ms | 14.75 ms | 17.95 ms |
| update every 10th row | 3.20 ms | 3.40 ms | 3.55 ms |
| swap rows | 1.05 ms | 1.45 ms | 1.50 ms |
| create 10k rows | 131.00 ms | 126.10 ms | 173.40 ms |
| bundle (gzip) | 23.4 kB | 34.2 kB | 40.9 kB |

The Vite wrapper compiles eligible views into Solid templates. The runtime renderer clones templates as it creates views and took longer to create rows in this benchmark.
