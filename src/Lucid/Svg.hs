{-# LANGUAGE OverloadedStrings       #-}

{-# OPTIONS -fno-warn-unused-imports #-}

-------------------------------------------------------------------------------
-- |
-- Module      :  Lucid.Svg
-- Copyright   :  (c) 2015 Jeffrey Rosenbluth
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  jeffrey.rosenbluth@gmail.com
--
-- DSL for creating SVG.
--
-------------------------------------------------------------------------------
module Lucid.Svg
  ( -- * Intro
    -- $intro
    -- * Re-exports
    module Lucid.Svg.Core
  , module Lucid.Svg.Path
  , module Lucid.Svg.Elements
  , module Lucid.Svg.Attributes
  -- * Rendering
  , prettyText
  ) where

import           Data.Functor.Identity
import           Data.Int               (Int64)
import           Data.Monoid
import           Data.Text.Lazy
import           Data.Text.Lazy         as LT
import           Data.Text.Lazy.Builder as B
import           Lucid.Svg.Core
import           Lucid.Svg.Attributes
import           Lucid.Svg.Elements
import           Lucid.Svg.Path

prettyText :: Element -> Text
prettyText svg = B.toLazyText $ LT.foldr go mempty text Nothing (-1)
  where
    text = renderText svg
    go c f Nothing n
      | c == '<' || c == '/' = f (Just c) n
    go c f (Just '<') n
      | c == '?' = "<?" <> f Nothing n
      | c == '!' = "<!" <> f Nothing n
      | c == '/' = "\n"
                    <> (B.fromLazyText $ LT.replicate n "  " )
                    <> "</"
                    <> f Nothing (n-1)
      | otherwise = "\n"
                    <> (B.fromLazyText $ LT.replicate (n+1)   "  " )
                    <> "<"
                    <> B.singleton c
                    <> f Nothing (n+1)
    go '>' f (Just _) n = "/>" <> f Nothing (n-1)
    go c f s n =  s' <> B.singleton c <> f Nothing n
      where  s' = maybe mempty B.singleton s

-- $intro
--
-- SVG elements in Lucid-Svg are written with a postfix ‘@_@’.
-- Some examples:
--
-- 'path_', 'circle_', 'color_', 'scale_'
--
-- Note: If you're testing in the REPL you need to add a type annotation to
-- indicate that you want SVG. In normal code your top-level
-- declaration signatures handle that.
--
-- Plain text is written using the @OverloadedStrings@ and
-- @ExtendedDefaultRules@ extensions, and is automatically escaped:
--
-- As in Lucid, elements nest by function application:
--
-- >>> g_ (text_ "Hello SVG") :: Element
-- <g><text>Hello SVG</text></g>
--
-- and elements are juxtaposed via monoidal append:
--
-- >>> text_ "Hello" <> text_ "SVG" :: Element
-- <text>Hello</text><text>SVG</text>
--
-- Attributes are set by providing an argument list. Each argument is set
-- using the 'bindAttr' function or operators, '<--' and '-->'.
--
-- >>> rect_ [Width <-- "100%", Height <-- "100%", "red" --> Fill] :: Element
-- <rect height="100%" width="100%" fill="red"></rect>
--
-- Path data can be constructed using the functions in 'Lucid.Svg.Path'
-- and combined monoidally:
--
-- @
-- path_ (
--   [ D <-- (mA 10 80 <> qA 52.5 10 95 80 <> tA 180 80 <> z)
--   , Stroke <-- "blue"
--   , Fill <-- "orange"
--   ]) nil
-- @
-- > <path d="M 10,80 Q 52.5,10 95,80 T 180,80 Z" stroke="blue" fill="orange"></path>
--
-- __A slightly longer example__:
--
-- > import Lucid.Svg
-- >
-- > svg :: Element -> Element
-- > svg content = do
-- >   doctype_
-- >   with (svg11_ content) [version_ "1.1", width_ "300" , height_ "200"]
-- >
-- > contents :: Element
-- > contents =
-- >      rect_ [Width <-- "100%", Height <-- "100%", Fill <-- "red"]
-- >   <> circle_ [Cx <-- "150", Cy <-- "100", R <-- "80", Fill <-- "green"]
-- >   <> text_ [ X <-- "150", Y <-- "125", FontSize <-- "60"
-- >            , TextAnchor <-- "middle", Fill <-- "white" ] "SVG"
-- >
-- >
-- > main :: IO ()
-- > main = do
-- >   putStrLn . T.unpack . renderText $ svg contents
-- <<http://i.imgur.com/dXu84xR.png>>
