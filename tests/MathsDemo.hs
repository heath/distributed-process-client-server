{-# LANGUAGE DeriveDataTypeable #-}

module MathsDemo 
  ( add
  , divide
  , launchMathServer
  ) where

import Control.Applicative
import Control.Distributed.Process hiding (call)
import Control.Distributed.Process.Platform.GenProcess
import Control.Distributed.Process.Platform.Time

import Data.Binary (Binary(..))
import Data.Typeable (Typeable)

data Add       = Add    Double Double deriving (Typeable)
data Divide    = Divide Double Double deriving (Typeable)
data DivByZero = DivByZero deriving (Typeable)

instance Binary Add where
  put (Add x y) = put x >> put y
  get = Add <$> get <*> get

instance Binary Divide where
  put (Divide x y) = put x >> put y
  get = Divide <$> get <*> get

instance Binary DivByZero where
  put DivByZero = return ()
  get = return DivByZero

-- public API

add :: ProcessId -> Double -> Double -> Process Double
add sid x y = call sid (Add x y)   

divide :: ProcessId -> Double -> Double -> Process Double
divide sid x y = call sid (Divide x y )

launchMathServer :: Process ProcessId
launchMathServer = 
  let server = statelessProcess {
      dispatchers = [
          handleCall_   (\(Add    x y) -> return (x + y))
        , handleCallIf_ (\(Divide _ y) -> y /= 0)
                        (\(Divide x y) -> return (x / y))
        , handleCall_   (\(Divide _ _) -> return DivByZero)
        
        , action        (\"stop" -> stop_ TerminateNormal)
        ]
    } :: Behaviour ()
  in spawnLocal $ start () startup server >> return ()
  where startup :: InitHandler () ()
        startup _ = return $ InitOk () Infinity
