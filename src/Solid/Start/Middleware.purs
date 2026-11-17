-- | Start-mode middleware. Set `start.middleware` to a module that exports
-- | `middleware :: MiddlewareFn`.
module Solid.Start.Middleware
  ( Middleware
  , MiddlewareFn
  , middleware
  ) where

import Prelude

import Control.Promise (Promise, fromAff, toAffE)
import Effect (Effect)
import Effect.Aff (Aff)
import Solid.Start.RequestEvent (RequestEvent, request)
import Web.Fetch.Request (Request)
import Web.Fetch.Response (Response)

-- | Gets the request event and the request; `next` continues down the chain
-- | with the request (the one given, or a rewritten one).
type Middleware = RequestEvent -> Request -> (Request -> Aff Response) -> Aff Response

foreign import data MiddlewareFn :: Type

middleware :: Middleware -> MiddlewareFn
middleware handler = middlewareImpl \event next ->
  fromAff (handler event (request event) (toAffE <<< next))

foreign import middlewareImpl :: (RequestEvent -> (Request -> Effect (Promise Response)) -> Effect (Promise Response)) -> MiddlewareFn
