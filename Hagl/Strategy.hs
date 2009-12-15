{-# LANGUAGE FlexibleContexts #-}

module Hagl.Strategy where

import Control.Monad       (liftM)
import Control.Monad.Trans (liftIO)
import System.IO.Error     (isUserError)

import Hagl.Core
import Hagl.Accessor (numMoves, players)
import Hagl.Selector (my)

-----------------------
-- Common Strategies --
-----------------------

-- Play a move.
play :: Move g -> Strategy s g
play = return

-- Construct a pure strategy. Always play the same move.
pure :: Move g -> Strategy s g
pure = return

-- Construct a mixed strategy. Play moves based on a distribution.
mixed :: [(Int, Move g)] -> Strategy s g
mixed = randomlyFrom . expandDist

-- Perform some pattern of moves periodically.
periodic :: Game g => [Move g] -> Strategy s g
periodic ms = my numMoves >>= \n -> return $ ms !! mod n (length ms)

-- Play a list of initial strategies, then a primary strategy thereafter.
thereafter :: Game g => [Strategy s g] -> Strategy s g -> Strategy s g
thereafter ss s = my numMoves >>= \n -> if n < length ss then ss !! n else s

-- Play an initial strategy for the first move, then a primary strategy thereafter.
atFirstThen :: Game g => Strategy s g -> Strategy s g -> Strategy s g
atFirstThen s = thereafter [s]

-- A human player, who enters moves on the console.
human :: (Game g, Read (Move g)) => Strategy () g
human = do n <- liftM name (my players)
           liftIO (putStrLn ("*** " ++ n ++ "'s turn ***"))
           liftIO getMove
  where getMove = putStr "Enter a move: " >> catch readLn retry
        retry e | isUserError e = putStrLn "Not a valid move... try again." >> getMove
                | otherwise     = ioError e
