module Site.Pages
  ( Snippets
  , landing
  , docs
  ) where

import Prelude

import Data.Array (concatMap)
import Site.Toc (Section(..), sectionId, sectionTitle, sections)
import Solid.DOM.HTML as H
import Solid.JSX (JSX, text)

-- | A sample's region name to its highlighted HTML (see `site/build.mjs`).
type Snippets = String -> String

repo :: String
repo = "https://github.com/arazorda/purs-solid"

pursuit :: String
pursuit = "https://pursuit.purescript.org/packages/purescript-purs-solid/0.1.0"

sample :: Snippets -> String -> JSX
sample snippets name = H.pre { class: "code" } (H.code { innerHTML: snippets name } [])

plain :: String -> JSX
plain source = H.pre { class: "code" } (H.code {} source)

c :: String -> JSX
c = H.code {}

header :: String -> JSX
header root = H.header { class: "top" }
  [ H.a { class: "brand", href: root <> "./" } [ H.span { class: "mark" } "λ", text "purs-solid" ]
  , H.nav {}
      [ H.a { href: root <> "docs/" } "Docs"
      , H.a { href: pursuit } "API"
      , H.a { href: repo } "GitHub"
      ]
  ]

footer :: JSX
footer = H.footer { class: "bottom" }
  [ H.p {}
      [ text "purs-solid · ISC license · "
      , H.a { href: repo } "GitHub"
      , text " · "
      , H.a { href: pursuit } "API reference on Pursuit"
      ]
  ]

landing :: Snippets -> String -> JSX
landing snippets demo = H.div { class: "page" }
  [ header ""
  , H.main {}
      [ H.section { class: "hero" }
          [ H.p { class: "eyebrow" } "PureScript bindings for Solid 2"
          , H.h1 {} "Fine-grained reactivity, checked by the compiler."
          , H.p { class: "lead" }
              "Signals, stores, async data, server rendering and hydration, a typed router and start mode, through Solid's public API. The types reject code that would misbehave at runtime."
          , H.div { class: "actions" }
              [ H.a { class: "button primary", href: "docs/" } "Read the docs"
              , H.a { class: "button", href: repo } "View on GitHub"
              ]
          ]
      , H.section { class: "demo" }
          [ H.div { class: "demo-code" } (sample snippets "counter")
          , H.div { class: "demo-live" }
              [ H.p { class: "caption" } "Rendered at build time, hydrated in your browser:"
              , H.div { id: "demo", innerHTML: demo } []
              ]
          ]
      , H.section { class: "features" }
          [ H.h2 {} "What the compiler catches"
          , H.div { class: "grid" } (feature snippets <$> features)
          ]
      , H.section { class: "closing" }
          [ H.h2 {} "Solid underneath"
          , H.p {}
              "The Vite wrapper compiles eligible views into the same templates as Solid JSX. The runtime renderer clones templates and applies props when it creates the view."
          , H.a { class: "button primary", href: "docs/" } "Get started"
          ]
      ]
  , footer
  ]

type Feature = { title :: String, body :: String, snippet :: String }

features :: Array Feature
features =
  [ { title: "Props checked per element"
    , body: "Each field is checked against the element's attributes and events. Every attribute takes a value or an accessor."
    , snippet: "feature-props"
    }
  , { title: "Setup can't write"
    , body: "Components run in Setup, which creates signals, memos and effects. Writes happen in handlers, in Effect."
    , snippet: "feature-setup"
    }
  , { title: "Async can't be read early"
    , body: "createAsync gives an Async with no get: render it, derive from it or await it, and loading shows a fallback."
    , snippet: "feature-async"
    }
  , { title: "Routes typed by their path"
    , body: "A route's params come from its pattern, :id<int> arrives as an Int, and href builds links from the same pattern."
    , snippet: "feature-routes"
    }
  , { title: "ARIA from the spec"
    , body: "aria-* attributes follow WAI-ARIA 1.2: booleans, numbers, and a type for each set of keywords."
    , snippet: "feature-aria"
    }
  , { title: "Server code stays on the server"
    , body: "In start mode a server module's functions never reach the browser, and what crosses the wire must be Serializable."
    , snippet: "server-function"
    }
  ]

feature :: Snippets -> Feature -> JSX
feature snippets { title, body, snippet } = H.article { class: "feature" }
  [ H.h3 {} title, H.p {} body, sample snippets snippet ]

type Guide = { modules :: Array String, content :: Array JSX }

docs :: Snippets -> String -> JSX
docs snippets contents = H.div { class: "page" }
  [ header "../"
  , H.div { class: "docs" }
      [ H.nav { id: "toc", class: "toc", "aria-label": "Contents", innerHTML: contents } []
      , H.main {} (concatMap section sections)
      ]
  , footer
  ]
  where
  section current =
    let
      id = sectionId current
      { modules, content } = guide snippets current
    in
      [ H.section { id, class: "doc" } $
          [ H.h2 {} (H.a { href: "#" <> id } (sectionTitle current)) ] <> content <> api modules
      ]

  api [] = []
  api modules =
    [ H.p { class: "api" } $ [ text "API: " ] <> concatMap
        (\name -> [ H.a { href: pursuit <> "/docs/" <> name } (c name), text " " ])
        modules
    ]

guide :: Snippets -> Section -> Guide
guide snippets = case _ of
  Install ->
    { modules: []
    , content:
        [ plain "spago install purs-solid"
        , H.p {} [ text "For a package set that predates the release, add ", c "purs-solid: 0.1.0", text " under ", c "workspace.extraPackages", text " in ", c "spago.yaml", text ", then run the same command." ]
        , H.p {} "Use Node.js 22.12 or later. Install the Solid 2 runtime and web renderer."
        , plain "npm install solid-js@2 @solidjs/web@2"
        , H.p {} [ text "Install Router and Meta when using ", c "Solid.Router", text " and ", c "Solid.Meta", text "." ]
        , plain "npm install @solidjs/router@2 @solidjs/meta@2"
        , H.p {} [ text "For compiled views or start mode, install the Git-hosted ", c "purs-solid/vite", text " wrapper with the Vite and Solid plugin versions required by its ", c "v0.1.0", text " tag." ]
        , plain ("npm install --save-dev @solidjs/vite-plugin@3.0.0 vite@8.3.8 \"git+" <> repo <> ".git#v0.1.0\"")
        , H.p {} [ text "Commit ", c "package-lock.json", text " and use ", c "npm ci", text " for repeatable installs." ]
        , H.p {} [ text "Bundle development builds with the ", c "development", text " export condition to get Solid's diagnostics." ]
        ]
    }
  Components ->
    { modules: [ "Solid.Component", "Solid.DOM", "Solid.DOM.HTML", "Solid.DOM.SVG", "Solid.DOM.Aria", "Solid.JSX" ]
    , content:
        [ H.p {} [ text "A ", c "Component", text " is a function from a props record to a view, built in ", c "Setup", text ". Elements take a record of props and their children; ", c "Component.element", text " renders a component with its props." ]
        , sample snippets "counter"
        , H.p {} [ text "Each field is checked against the element's row, so ", c "href", text " only type-checks on elements that have it. Attributes take a value or an ", c "Accessor", text "; event fields take a handler for the row's event type. Children are one element, text (a ", c "String", text " or an ", c "Accessor String", text "), or an array of elements; mix text into an array with ", c "text", text ". Void elements like ", c "H.img", text " take only the record." ]
        , sample snippets "elements"
        , H.p {} "Beyond the element's own attributes, a record can have:"
        , H.ul {}
            [ H.li {} [ c "ref", text ": gets the element once it's created, typed by the element." ]
            , H.li {} [ c "class", text ": a string, or a record of class toggles." ]
            , H.li {} [ c "style", text ": CSS text, or a record of properties." ]
            , H.li {} [ c "bindValue", text " / ", c "bindChecked", text ": bind a field's value or a checkbox to a signal both ways." ]
            , H.li {} [ c "role", text " and the ", c "aria-*", text " attributes, typed by WAI-ARIA 1.2 (", c "Solid.DOM.Aria", text ")." ]
            , H.li {} [ c "data-*", text " attributes, case-sensitive ", c "on:name", text " listeners, and ", c "innerHTML", text " or ", c "textContent", text "." ]
            ]
        , sample snippets "fields"
        , H.p {} [ text "SVG elements live in ", c "Solid.DOM.SVG", text ". Use ", c "element", text " for a custom tag. Name handlers like ", c "onClick", text " or ", c "on:customEvent", text ". Attribute names are passed through as written." ]
        , sample snippets "svg"
        , sample snippets "untyped"
        ]
    }
  Reactivity ->
    { modules: [ "Solid.Signal", "Solid.Reactivity", "Solid.Setup", "Solid.Lifecycle", "Solid.Context" ]
    , content:
        [ H.p {} [ text "Component bodies create signals, memos and effects in ", c "Setup", text ". Use ", c "sample", text " for a one-time read in setup and pass an ", c "Accessor", text " for values that should stay reactive. ", c "get", text ", ", c "set", text " and ", c "modify", text " run in ", c "Effect", text ", for example in a handler." ]
        , sample snippets "signals"
        , H.p {} [ text "An effect splits into a tracked computation and an untracked apply step that can return a cleanup. Use ", c "liftSetup", text " for setup effects such as creating a ref." ]
        ]
    }
  ControlFlow ->
    { modules: [ "Solid.Control" ]
    , content:
        [ H.p {} [ text "Control flow creates a view when its branch is shown. Use ", c "forEachBy", text " with a stable key such as a record's ID to reuse rows when the array changes." ]
        , sample snippets "control"
        , H.p {} [ c "caseOn", text " switches on a data type and rebuilds a branch only when the key changes, here the constructor." ]
        , sample snippets "case"
        ]
    }
  Stores ->
    { modules: [ "Solid.Store" ]
    , content:
        [ H.p {} [ text "Stores hold nested state. Updates are pure ", c "Update", text " values on typed paths, applied to Solid's draft; reads go through cursors, so each row only tracks the fields it shows." ]
        , sample snippets "store"
        ]
    }
  Async ->
    { modules: [ "Solid.Async", "Solid.Action" ]
    , content:
        [ H.p {} [ c "createAsync", text " runs an ", c "Aff", text " for each value of its input and kills superseded ones. The result is an ", c "Async", text ", which may not have loaded, so it has no ", c "get", text ": render it, derive from it, or await it with ", c "resolve", text ". ", c "loading", text " shows a fallback until it's ready, and ", c "errored", text " catches failures." ]
        , sample snippets "async"
        , H.p {} [ text "Use ", c "Solid.Action", text " for transactional mutations. Make optimistic writes inside an ", c "Action", text " or a router action's ", c "onSubmit", text " hook." ]
        ]
    }
  Router ->
    { modules: [ "Solid.Router", "Solid.Router.Path", "Solid.Router.Search", "Solid.Router.Query", "Solid.Router.Action" ]
    , content:
        [ H.p {} [ c "route @\"/users/:id<int>\"", text " gives its component ", c "params :: Accessor { id :: Int }", text ". Build links from the same pattern with ", c "href", text ". The router handles plain anchors and marks exact pathname and query matches with ", c "aria-current=\"page\"", text ". A row type defines the search parameters." ]
        , sample snippets "router"
        , H.p {} [ c "Solid.Router.Query", text " caches route data. ", c "Solid.Router.Action", text " supports forms, tracked submissions and revalidation. Router 2 deprecates ", c "useAction", text ". For programmatic mutations, invoke a server function with ", c "call", text " or use ", c "Solid.Action", text "." ]
        ]
    }
  Ssr ->
    { modules: [ "Solid.Web", "Solid.Web.SSR", "Solid.Meta", "Solid.Errors" ]
    , content:
        [ H.p {} [ text "Render on the server with ", c "renderToString", text ", await server data with ", c "renderToStringAsync", text ", or stream with ", c "renderToReadableStream", text ". Hydrate the same view on the client." ]
        , sample snippets "ssr"
        , H.p {} [ c "createAsync", text " loads in the browser by default. Supply ", c "ssr: serialized", text " or ", c "ssr: withCodec encode decode", text " to ", c "createAsyncWith", text " to send the server-loaded value to hydration. Use ", c "renderToStringWithHead", text " to collect ", c "Solid.Meta", text " tags when assembling the document yourself." ]
        ]
    }
  StartMode ->
    { modules: [ "Solid.Start.ServerFunction", "Solid.Start.UseServer", "Solid.Start.RequestEvent", "Solid.Start.Response", "Solid.Start.Middleware" ]
    , content:
        [ H.p {} [ text "Export an ", c "app", text " component from module ", c "App", text " and run ", c "spago build", text " before starting Vite. The wrapper accepts PureScript module names for ", c "start.app", text " and ", c "start.middleware", text ". A middleware module exports ", c "middleware :: MiddlewareFn", text "." ]
        , plain "import { defineConfig } from \"vite\";\nimport solid from \"purs-solid/vite\";\n\nexport default defineConfig({ plugins: [solid({ start: true, ssr: true })] });"
        , H.p {} [ text "The wrapper compiles eligible views to Solid templates. Set ", c "compileViews: false", text " to use the runtime renderer for every view. Set ", c "start.nodeServer", text " to ", c "true", text " to generate a Node server." ]
        , H.p {} [ text "Re-export ", c "Solid.Start.UseServer", text " from a server module and define its functions with ", c "serverFunction", text ". Use ", c "Serializable", text " arguments and results." ]
        , sample snippets "server-function"
        , H.p {} [ text "Invoke a server function in ", c "Aff", text " with ", c "call", text ". Use ", c "queryServer", text " for a cached read or ", c "serverAction", text " to wrap a mutation that returns a ", c "Reply", text "." ]
        ]
    }
  Testing ->
    { modules: [ "Solid.Testing" ]
    , content:
        [ H.p {} [ c "Solid.Testing", text " mounts views into a DOM (happy-dom works) and waits for Solid to settle. It doesn't depend on a test framework." ]
        , sample snippets "testing"
        ]
    }
