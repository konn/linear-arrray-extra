{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UnboxedTuples #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}

module Data.Array.Mutable.Unlifted.Linear.Extra (
  allocL,
  module Data.Array.Mutable.Unlifted.Linear,
) where

import Data.Alloc.Linearly.Token
import Data.Array.Mutable.Unlifted.Linear
import GHC.Exts (unsafeCoerce#)
import qualified GHC.Exts as GHC
import Prelude.Linear
import qualified Prelude as P

allocL :: Linearly %1 -> Int -> a -> Array# a
allocL l (GHC.I# s) a =
  consume l & \() ->
    case GHC.runRW# P.$ GHC.newArray# s a of
      (# _, arr #) -> unsafeCoerce# arr
{-# NOINLINE allocL #-} -- prevents runRW# from floating outwards