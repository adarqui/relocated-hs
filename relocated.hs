{-# LANGUAGE OverloadedStrings #-}

import Data.Maybe
import RelocateInc
import Relocate
import Service
import Fire
import Debug

import HMisc.StatInc
import HMisc.Stat
import HMisc.Time
import HMisc.Pool

main :: IO ()
main =
	blockSigs >>
	load "config.json" >>=
	dump >>=
	mapM_ launch . mapMaybe sanitizeRelocator . relocators . root . fromJust


launch :: Relocator -> IO ()
launch r = do
	input <- createBoundedPool (maxProc r) Service.doRelocate
	loop input r


loop :: ThreadChan ThreadCTX -> Relocator -> IO ()
loop input r = do
	sleep $ intervalPoll r
	poll input r
	loop input r


poll :: ThreadChan ThreadCTX -> Relocator -> IO ()
poll input r = do
	epoch <- getTime
	relpoint <- findRelocator r
	relpair <- relPoint2Pair relpoint elapsed epoch
	fireOne input relpair
	where
		elapsed = intervalElapsed r