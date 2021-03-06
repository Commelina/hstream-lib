{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE NoImplicitPrelude #-}

module HStream.Stream.SessionWindows
  ( SessionWindows (..),
    mkSessionWindows,
    SessionWindowKey,
    sessionWindowKeySerializer,
    sessionWindowKeyDeserializer,
    sessionWindowKeySerde,
  )
where

import Data.Binary.Get
import qualified Data.ByteString.Builder as BB
import HStream.Encoding
import HStream.Stream.TimeWindows
import RIO

data SessionWindows = SessionWindows
  { swInactivityGap :: Int64,
    swGraceMs :: Int64
  }

mkSessionWindows :: Int64 -> SessionWindows
mkSessionWindows inactivityGap =
  SessionWindows
    { swInactivityGap = inactivityGap,
      swGraceMs = 24 * 3600 * 1000
    }

type SessionWindowKey k = TimeWindowKey k

sessionWindowKeySerializer :: Serializer k -> Serializer (TimeWindowKey k)
sessionWindowKeySerializer kSerializer = Serializer $ \TimeWindowKey {..} ->
  let keyBytes = runSer kSerializer twkKey
      bytesBuilder = BB.int64BE (tWindowStart twkWindow) <> BB.int64BE (tWindowEnd twkWindow) <> BB.lazyByteString keyBytes
   in BB.toLazyByteString bytesBuilder

-- 为了反序列化出 TimeWindow,
-- 还需要传入 WindowSize,
-- 因为序列化的时候仅仅传入了 windowStartTimestamp.
sessionWindowKeyDeserializer :: Deserializer k -> Deserializer (TimeWindowKey k)
sessionWindowKeyDeserializer kDeserializer = Deserializer $ runGet decodeWindowKey
  where
    decodeWindowKey = do
      startTs <- getInt64be
      endTs <- getInt64be
      keyBytes <- getRemainingLazyByteString
      return
        TimeWindowKey
          { twkKey = runDeser kDeserializer keyBytes,
            twkWindow = mkTimeWindow startTs endTs
          }

sessionWindowKeySerde :: Serde k -> Serde (TimeWindowKey k)
sessionWindowKeySerde kSerde =
  Serde
    { serializer = sessionWindowKeySerializer $ serializer kSerde,
      deserializer = sessionWindowKeyDeserializer (deserializer kSerde)
    }
