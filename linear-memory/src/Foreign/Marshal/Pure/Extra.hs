{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UnboxedTuples #-}
{-# LANGUAGE UnliftedNewtypes #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Foreign.Marshal.Pure.Extra (
  get,
  set,
  release,
  modify,
  modify_,
  module Foreign.Marshal.Pure,
) where

import Control.Exception (mask_)
import Foreign
import Foreign.Marshal.Pure
import Foreign.Marshal.Pure.Internal
import GHC.Exts (runRW#)
import GHC.IO (unIO, unsafeDupablePerformIO)
import GHC.IO.Unsafe (noDuplicate, unsafePerformIO)
import Prelude.Linear
import qualified Unsafe.Linear as Unsafe
import qualified Prelude as P

instance KnownRepresentable Int8

instance Representable Int8 where
  type AsKnown Int8 = Int8
  toKnown = id
  ofKnown = id

instance KnownRepresentable Int16

instance Representable Int16 where
  type AsKnown Int16 = Int16
  toKnown = id
  ofKnown = id

instance KnownRepresentable Int32

instance Representable Int32 where
  type AsKnown Int32 = Int32
  toKnown = id
  ofKnown = id

instance KnownRepresentable Int64

instance Representable Int64 where
  type AsKnown Int64 = Int64
  toKnown = id
  ofKnown = id

instance KnownRepresentable Word8

instance Representable Word8 where
  type AsKnown Word8 = Word8
  toKnown = id
  ofKnown = id

instance KnownRepresentable Word16

instance Representable Word16 where
  type AsKnown Word16 = Word16
  toKnown = id
  ofKnown = id

instance KnownRepresentable Word32

instance Representable Word32 where
  type AsKnown Word32 = Word32
  toKnown = id
  ofKnown = id

instance KnownRepresentable Word64

instance Representable Word64 where
  type AsKnown Word64 = Word64
  toKnown = id
  ofKnown = id

instance KnownRepresentable Double

instance Representable Double where
  type AsKnown Double = Double
  toKnown = id
  ofKnown = id

instance KnownRepresentable Float

instance Representable Float where
  type AsKnown Float = Float
  toKnown = id
  ofKnown = id

get :: (Representable a, Dupable a) => Box a %1 -> (a, Box a)
{-# NOINLINE get #-}
get = Unsafe.toLinear \box@(Box _ b) ->
  case runRW# (unIO (reprPeek b)) of
    (# _, !a #) ->
      dup a & \(a, _) -> (a, box)

-- | __Warning__: non-atomic
modify :: (Representable a) => (a %1 -> (a, Ur b)) -> Box a %1 -> (Ur b, Box a)
{-# NOINLINE modify #-}
modify = Unsafe.toLinear2 \f box@(Box _ ptr) -> unsafePerformIO do
  !a <- reprPeek ptr
  f a & \(!a, !urb) -> do
    reprPoke ptr a
    P.pure (urb, box)

-- | __Warning__: non-atomic
modify_ :: (Representable a) => (a %1 -> a) -> Box a %1 -> Box a
modify_ = Unsafe.toLinear2 \f box@(Box _ ptr) -> unsafePerformIO do
  !a <- reprPeek ptr
  f a & \ !a -> do
    () <- reprPoke ptr a
    P.pure box

set :: (Representable a) => a -> Box a %1 -> Box a
{-# NOINLINE set #-}
set !a = Unsafe.toLinear \(Box poolPtr ptr) ->
  case runRW# (unIO (noDuplicate P.>> reprPoke ptr a)) of
    (# _, () #) -> Box poolPtr ptr

release :: Box a %1 -> ()
release (Box poolPtr ptr) = unsafeDupablePerformIO $ mask_ $ do
  delete P.=<< peek poolPtr
  free ptr
  free poolPtr

instance Consumable (Box a) where
  consume = release
