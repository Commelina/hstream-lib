{-# LANGUAGE StrictData #-}
{-# LANGUAGE NoImplicitPrelude #-}

module HStream.Util
  ( getCurrentTimestamp,
  )
where

import Data.Time
import Data.Time.Clock.POSIX
import HStream.Type
import RIO

posixTimeToMilliSeconds :: POSIXTime -> Timestamp
posixTimeToMilliSeconds =
  floor . (* 1000) . nominalDiffTimeToSeconds

-- return millisecond timestamp
getCurrentTimestamp :: IO Timestamp
getCurrentTimestamp = posixTimeToMilliSeconds <$> getPOSIXTime
