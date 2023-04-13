module Reauth exposing (reauth)

import Effect exposing (Effect)
import Shared


reauth : Effect msg
reauth =
    Effect.fromShared Shared.Reauth
