
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}

{-# LANGUAGE RankNTypes #-}

module Data.Json.Argonaut where

import Control.Applicative as Applicative((*>), (<*))
import Control.Applicative(Alternative((<|>), many))
import Data.Digit
import Data.List.NonEmpty
import Data.Foldable(asum)
import Data.Maybe
import Text.Parser.Char
import Text.Parser.Combinators
-- import Data.Text(Text)
import Papa

-- import qualified Prelude as Prelude(error, undefined)

-- $setup
-- >>> :set -XNoImplicitPrelude
-- >>> :set -XFlexibleContexts
-- >>> :set -XOverloadedStrings
-- >>> import Control.Applicative as Applicative((<*))
-- >>> import Data.Either(isLeft)
-- >>> import Data.Text(pack)
-- >>> import Data.Text.Arbitrary
-- >>> import Text.Parsec(Parsec, ParseError, parse)
-- >>> import Test.QuickCheck(Arbitrary(..))
-- >>> let testparse :: Parsec Text () a -> Text -> Either ParseError a; testparse p = parse p "test"
-- >>> let testparsetheneof :: Parsec Text () a -> Text -> Either ParseError a; testparsetheneof p = testparse (p Applicative.<* eof)
-- >>> let testparsethennoteof :: Parsec Text () a -> Text -> Either ParseError a; testparsethennoteof p = testparse (p Applicative.<* anyChar)
-- >>> let testparsethen :: Parsec Text () a -> Text -> Either ParseError (a, Char); testparsethen p = parse ((,) <$> p <*> Text.Parser.Char.anyChar) "test"

----

data HexDigit =
  D0
  | D1
  | D2
  | D3
  | D4
  | D5
  | D6
  | D7
  | D8
  | D9
  | Da
  | Db
  | Dc
  | Dd
  | De
  | Df
  | DA
  | DB
  | DC
  | DD
  | DE
  | DF
  deriving (Eq, Ord)

instance Show HexDigit where
  show D0 =
    "0"
  show D1 =
    "1"
  show D2 =
    "2"
  show D3 =
    "3"
  show D4 =
    "4"
  show D5 =
    "5"
  show D6 =
    "6"
  show D7 =
    "7"
  show D8 =
    "8"
  show D9 =
    "9"
  show Da =
    "a"
  show Db =
    "b"
  show Dc =
    "c"
  show Dd =
    "d"
  show De =
    "e"
  show Df =
    "f"
  show DA =
    "A"
  show DB =
    "B"
  show DC =
    "C"
  show DD =
    "D"
  show DE =
    "E"
  show DF =
    "F"
    
data HexDigit4 =
  HexDigit4
    HexDigit
    HexDigit
    HexDigit
    HexDigit
  deriving (Eq, Ord)

instance Show HexDigit4 where
  show (HexDigit4 q1 q2 q3 q4) =
    concat
      [
        show q1
      , show q2
      , show q3
      , show q4
      ]

newtype JCharUnescaped =
  JCharUnescaped
    Char
  deriving (Eq, Ord, Show)

class HasJCharUnescaped a where
  jCharUnescaped ::
    Lens'
      a
      JCharUnescaped

instance HasJCharUnescaped JCharUnescaped where
  jCharUnescaped =
    id

class AsJCharUnescaped a where
  _JCharUnescaped ::
    Prism'
      a
      JCharUnescaped

instance AsJCharUnescaped JCharUnescaped where
  _JCharUnescaped =
    id

instance AsJCharUnescaped Char where
  _JCharUnescaped =
    prism'
      (\(JCharUnescaped c) -> c)
      (\c ->  if any (\f -> f c) [(== '"'), (== '\\'), (\x -> x >= '\x00' && x <= '\x1f')]
                then
                  Nothing
                else
                  Just (JCharUnescaped c)
      )

data JCharEscaped =
  QuotationMark
  | ReverseSolidus
  | Solidus
  | Backspace
  | FormFeed
  | LineFeed
  | CarriageReturn
  | Tab
  | Hex HexDigit4
  deriving (Eq, Ord, Show)

data JChar =
  EscapedJChar JCharEscaped
  | UnescapedJChar JCharUnescaped
  deriving (Eq, Ord, Show)

newtype JString =
  JString
    [JChar]
  deriving (Eq, Ord, Show)

newtype JNumber =
  JNumber {
    _jnumber ::
      Double
  } deriving (Eq, Ord, Show)

data JAssoc s =
  JAssoc {
    _key ::
      LeadingTrailing JString s
  , _value ::
      LeadingTrailing (Json s) s
  }
  deriving (Eq, Ord, Show)

newtype JObject s =
  JObject {
    _jobjectL ::
      [LeadingTrailing (JAssoc s) s]
  } deriving (Eq, Ord, Show)

data LeadingTrailing a s =
  LeadingTrailing {
    _leading ::
      s
  , _a ::
      a
  , _trailing ::
      s
  } deriving (Eq, Ord, Show)

--  http://rfc7159.net/rfc7159
data Json s =
  JsonNull s
  | JsonBool Bool s
  | JsonNumber JNumber s
  | JsonString JString s
  | JsonArray (Jsons s) s
  | JsonObject (JObject s) s
  deriving (Eq, Ord, Show)

newtype Jsons s =
  Jsons {
    _jsonsL ::
      [LeadingTrailing (Json s) s]
  } deriving (Eq, Ord, Show)


makeClassy ''HexDigit
makeClassyPrisms ''HexDigit
makeClassy ''HexDigit4
makeClassy ''JCharEscaped
makeClassyPrisms ''JCharEscaped
makeClassy ''JChar
makeClassyPrisms ''JChar
makeWrapped ''JString
makeClassy ''JNumber
makeWrapped ''JNumber
makeClassy ''JAssoc
makeClassy ''JObject
makeWrapped ''JObject
makeClassy ''Json
makeClassyPrisms ''Json
makeClassy ''Jsons
makeWrapped ''Jsons

-- |
--
-- >>> testparse (parseJsonNull (return ())) "null" 
-- Right (JsonNull ())
--
-- >>> testparsetheneof (parseJsonNull (return ())) "null" 
-- Right (JsonNull ())
--
-- >>> testparsethennoteof (parseJsonNull (return ())) "nullx" 
-- Right (JsonNull ())
--
-- prop> x /= "null" ==> isLeft (testparse (parseJsonNull (return ())) x)
parseJsonNull ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonNull p =
  JsonNull <$ text "null" <*> p

-- |
--
-- >>> testparse (parseJsonBool (return ())) "true" 
-- Right (JsonBool True ())
--
-- >>> testparse (parseJsonBool (return ())) "false" 
-- Right (JsonBool False ())
---
-- >>> testparsetheneof (parseJsonBool (return ())) "true" 
-- Right (JsonBool True ())
--
-- >>> testparsetheneof (parseJsonBool (return ())) "false" 
-- Right (JsonBool False ())
---
-- >>> testparsethennoteof (parseJsonBool (return ())) "truex" 
-- Right (JsonBool True ())
--
-- >>> testparsethennoteof (parseJsonBool (return ())) "falsex" 
-- Right (JsonBool False ())
--
-- prop> (x `notElem` ["true", "false"]) ==> isLeft (testparse (parseJsonBool (return ())) x)
parseJsonBool ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonBool p =
  let b q t = JsonBool q <$ text t <*> p
  in  b False "false" <|> b True "true"

parseJNumber ::
  CharParsing f =>
  f (JNumber)
parseJNumber =
  -- todo
  parseJNumber

parseJsonNumber ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonNumber p =
  JsonNumber <$> parseJNumber <*> p

-- |
--
-- >>> testparse parseHexDigit "0" 
-- Right 0
--
-- >>> testparse parseHexDigit "1" 
-- Right 1
--
-- >>> testparse parseHexDigit "9" 
-- Right 9
--
-- >>> testparse parseHexDigit "a" 
-- Right a
--
-- >>> testparse parseHexDigit "f" 
-- Right f
--
-- >>> testparse parseHexDigit "A" 
-- Right A
--
-- >>> testparse parseHexDigit "F" 
-- Right F
--
-- >>> testparsetheneof parseHexDigit "F" 
-- Right F
--
-- >>> testparsethennoteof parseHexDigit "Fx" 
-- Right F
parseHexDigit ::
  CharParsing f =>
  f HexDigit
parseHexDigit =
  asum
    [
      D0 <$ char '0'
    , D1 <$ char '1'
    , D2 <$ char '2'
    , D3 <$ char '3'
    , D4 <$ char '4'
    , D5 <$ char '5'
    , D6 <$ char '6'
    , D7 <$ char '7'
    , D8 <$ char '8'
    , D9 <$ char '9'
    , Da <$ char 'a'
    , Db <$ char 'b'
    , Dc <$ char 'c'
    , Dd <$ char 'd'
    , De <$ char 'e'
    , Df <$ char 'f'
    , DA <$ char 'A'
    , DB <$ char 'B'
    , DC <$ char 'C'
    , DD <$ char 'D'
    , DE <$ char 'E'
    , DF <$ char 'F'
    ]

-- |
--
-- >>> testparse parseHexDigit4 "1234"
-- Right 1234
--
-- >>> testparse parseHexDigit4 "12aF"
-- Right 12aF
--
-- >>> testparse parseHexDigit4 "aBcD"
-- Right aBcD
--
-- >>> testparsetheneof parseHexDigit4 "12aF"
-- Right 12aF
--
-- >>> testparsethennoteof parseHexDigit4 "12aFx"
-- Right 12aF
parseHexDigit4 ::
  CharParsing f =>
  f HexDigit4
parseHexDigit4 =
  HexDigit4 <$> parseHexDigit <*> parseHexDigit <*> parseHexDigit <*> parseHexDigit

-- |
--
-- >>> testparse parseJCharUnescaped "a" 
-- Right (JCharUnescaped 'a')
--
-- >>> testparse parseJCharUnescaped "\8728" 
-- Right (JCharUnescaped '\8728')
--
-- >>> testparsetheneof parseJCharUnescaped "a" 
-- Right (JCharUnescaped 'a')
--
-- >>> testparsethennoteof parseJCharUnescaped "ax" 
-- Right (JCharUnescaped 'a')
parseJCharUnescaped ::
  CharParsing f =>
  f JCharUnescaped
parseJCharUnescaped =
  JCharUnescaped <$> satisfy (has _JCharUnescaped)

-- |
--
-- >>> testparse parseJCharEscaped "\\\""
-- Right QuotationMark
--
-- >>> testparse parseJCharEscaped "\\\\"
-- Right ReverseSolidus
--
-- >>> testparse parseJCharEscaped "\\/"
-- Right Solidus
--
-- >>> testparse parseJCharEscaped "\\b"
-- Right Backspace
--
-- >>> testparse parseJCharEscaped "\\f"
-- Right FormFeed
--
-- >>> testparse parseJCharEscaped "\\n"
-- Right LineFeed
--
-- >>> testparse parseJCharEscaped "\\r"
-- Right CarriageReturn
--
-- >>> testparse parseJCharEscaped "\\t"
-- Right Tab
--
-- >>> testparse parseJCharEscaped "\\u1234"
-- Right (Hex 1234)
--
-- >>> testparsetheneof parseJCharEscaped "\\t"
-- Right Tab
--
-- >>> testparsethennoteof parseJCharEscaped "\\tx"
-- Right Tab
parseJCharEscaped ::
  CharParsing f =>
  f JCharEscaped
parseJCharEscaped =
  let e =
        asum
          ((\(c, p) -> char c Applicative.*> pure p) <$>
            [
              ('"' , QuotationMark)
            , ('\\', ReverseSolidus)
            , ('/' , Solidus)
            , ('b' , Backspace)
            , ('f' , FormFeed)
            , ('n' , LineFeed)
            , ('r' , CarriageReturn)
            , ('t' , Tab)
            ])
      h =
        Hex <$> (char 'u' Applicative.*> parseHexDigit4)
  in  char '\\' Applicative.*> (e <|> h)

-- |
--
-- >>> testparse parseJChar "a"
-- Right (UnescapedJChar (JCharUnescaped 'a'))
--
-- >>> testparse parseJChar "\\u1234"
-- Right (EscapedJChar (Hex 1234))
--
-- >>> testparse parseJChar "\\r"
-- Right (EscapedJChar CarriageReturn)
--
-- >>> testparsetheneof parseJChar "a"
-- Right (UnescapedJChar (JCharUnescaped 'a'))
--
-- >>> testparsethennoteof parseJChar "ax"
-- Right (UnescapedJChar (JCharUnescaped 'a'))
parseJChar ::
  CharParsing f =>
  f JChar
parseJChar =
  asum
    [
      EscapedJChar <$> try parseJCharEscaped
    , UnescapedJChar <$> parseJCharUnescaped
    ]

-- |
--
-- >>> testparse parseJString "\"\""
-- Right (JString [])
--
-- >>> testparse parseJString "\"abc\""
-- Right (JString [UnescapedJChar (JCharUnescaped 'a'),UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c')])
--
-- >> testparse parseJString "\"a\\rbc\""
-- Right (JString [UnescapedJChar (JCharUnescaped 'a'),EscapedJChar CarriageReturn,UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c')])
--
-- >>> testparse parseJString "\"a\\rbc\\uab12\\ndef\\\"\""
-- Right (JString [UnescapedJChar (JCharUnescaped 'a'),EscapedJChar CarriageReturn,UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c'),EscapedJChar (Hex ab12),EscapedJChar LineFeed,UnescapedJChar (JCharUnescaped 'd'),UnescapedJChar (JCharUnescaped 'e'),UnescapedJChar (JCharUnescaped 'f'),EscapedJChar QuotationMark])
--
-- >>> testparsetheneof parseJString "\"\""
-- Right (JString [])
--
-- >>> testparsetheneof parseJString "\"abc\""
-- Right (JString [UnescapedJChar (JCharUnescaped 'a'),UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c')])
--
-- >>> testparsethennoteof parseJString "\"a\"\\u"
-- Right (JString [UnescapedJChar (JCharUnescaped 'a')])
--
-- >>> testparsethennoteof parseJString "\"a\"\t"
-- Right (JString [UnescapedJChar (JCharUnescaped 'a')])
parseJString ::
  CharParsing f =>
  f JString
parseJString =
  char '"' Applicative.*> (JString <$> many parseJChar) Applicative.<* char '"'

-- |
--
-- >>> testparse (parseJsonString (return ())) "\"\""
-- Right (JsonString (JString []) ())
--
-- >>> testparse (parseJsonString (return ())) "\"abc\""
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a'),UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c')]) ())
--
-- >> testparse (parseJsonString (return ())) "\"a\\rbc\""
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a'),EscapedJChar CarriageReturn,UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c'),EscapedJChar (Hex ab12),EscapedJChar LineFeed,UnescapedJChar (JCharUnescaped 'd'),UnescapedJChar (JCharUnescaped 'e'),UnescapedJChar (JCharUnescaped 'f'),EscapedJChar QuotationMark]) ())
--
-- >>> testparse (parseJsonString (return ())) "\"a\\rbc\\uab12\\ndef\\\"\""
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a'),EscapedJChar CarriageReturn,UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c'),EscapedJChar (Hex ab12),EscapedJChar LineFeed,UnescapedJChar (JCharUnescaped 'd'),UnescapedJChar (JCharUnescaped 'e'),UnescapedJChar (JCharUnescaped 'f'),EscapedJChar QuotationMark]) ())
--
-- >>> testparsetheneof (parseJsonString (return ())) "\"\""
-- Right (JsonString (JString []) ())
--
-- >>> testparsetheneof (parseJsonString (return ())) "\"abc\""
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a'),UnescapedJChar (JCharUnescaped 'b'),UnescapedJChar (JCharUnescaped 'c')]) ())
--
-- >>> testparsethennoteof (parseJsonString (return ())) "\"a\"\\u"
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a')]) ())
--
-- >>> testparsethennoteof (parseJsonString (return ())) "\"a\"\t"
-- Right (JsonString (JString [UnescapedJChar (JCharUnescaped 'a')]) ())
parseJsonString ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonString p =
  JsonString <$> parseJString <*> p

parseJsons ::
  CharParsing f =>
  f s
  -> f (Jsons s)
parseJsons s =
  Jsons <$>
    (
      char '[' Applicative.*>
      sepBy (parseLeadingTrailing s (parseJson s)) (char ',') Applicative.<*
      char ']'
    )

parseJsonArray ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonArray p =
  JsonArray <$> parseJsons p <*> p

parseJAssoc ::
  CharParsing f =>
  f s
  -> f (JAssoc s)
parseJAssoc s =
  JAssoc <$> parseLeadingTrailing s parseJString Applicative.<* char ':' <*> parseLeadingTrailing s (parseJson s)

parseJObject ::
  CharParsing f =>
  f s
  -> f (JObject s)
parseJObject s =
  JObject <$>
    (
      char '{' Applicative.*>
      sepBy (parseLeadingTrailing s (parseJAssoc s)) (char ',') Applicative.<*
      char '}'
    )

parseJsonObject ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJsonObject p =
  JsonObject <$> parseJObject p <*> p

parseJson ::
  CharParsing f =>
  f s
  -> f (Json s)
parseJson =  
  asum . sequence
    [
      parseJsonNull 
    , parseJsonBool 
    , parseJsonNumber
    , parseJsonString 
    , parseJsonArray 
    , parseJsonObject 
    ]

parseLeadingTrailing ::
  Applicative f =>
  f s
  -> f a
  -> f (LeadingTrailing a s)
parseLeadingTrailing s a =
  LeadingTrailing <$> s <*> a <*> s

----

data Digit1to9 =
  D1_1to9
  | D2_1to9
  | D3_1to9
  | D4_1to9
  | D5_1to9
  | D6_1to9
  | D7_1to9
  | D8_1to9
  | D9_1to9
  deriving (Eq, Ord, Show)

-- |
--
-- >>> testparse parseDigit1to9 "1"
-- Right D1_1to9
--
-- >>> testparse parseDigit1to9 "9"
-- Right D9_1to9
--
-- >>> testparse parseDigit1to9 "5"
-- Right D5_1to9
--
-- >>> testparsetheneof parseDigit1to9 "1"
-- Right D1_1to9
--
-- >>> testparsetheneof parseDigit1to9 "9"
-- Right D9_1to9
--
-- >>> testparsetheneof parseDigit1to9 "5"
-- Right D5_1to9
--
-- >>> isLeft (testparsetheneof parseDigit1to9 "0")
-- True
--
-- >>> testparsethennoteof parseDigit1to9 "1a"
-- Right D1_1to9
--
-- >>> testparsethennoteof parseDigit1to9 "9a"
-- Right D9_1to9
--
-- >>> testparsethennoteof parseDigit1to9 "5a"
-- Right D5_1to9
parseDigit1to9 ::
  CharParsing f =>
  f Digit1to9
parseDigit1to9 =
  asum [
    D1_1to9 <$ char '1'
  , D2_1to9 <$ char '2'
  , D3_1to9 <$ char '3'
  , D4_1to9 <$ char '4'
  , D5_1to9 <$ char '5'
  , D6_1to9 <$ char '6'
  , D7_1to9 <$ char '7'
  , D8_1to9 <$ char '8'
  , D9_1to9 <$ char '9'
  ]

data JInt =
  JZero
  | JInt Digit1to9 [Digit]
  deriving (Eq, Ord, Show)

-- |
--
-- >>> testparse parseJInt "1"
-- Right (JInt D1_1to9 [])
--
-- >>> testparse parseJInt "9"
-- Right (JInt D9_1to9 [])
--
-- >>> testparse parseJInt "10"
-- Right (JInt D1_1to9 [0])
--
-- >>> testparse parseJInt "39"
-- Right (JInt D3_1to9 [9])
--
-- >>> testparse parseJInt "393564"
-- Right (JInt D3_1to9 [9,3,5,6,4])
--
-- >>> testparse parseJInt "0"
-- Right JZero
--
-- >>> testparsethennoteof parseJInt "00"
-- Right JZero
--
-- >>> testparsethennoteof parseJInt "01"
-- Right JZero
--
-- >>> testparsetheneof parseJInt "1"
-- Right (JInt D1_1to9 [])
--
-- >>> testparsetheneof parseJInt "9"
-- Right (JInt D9_1to9 [])
--
-- >>> testparsetheneof parseJInt "10"
-- Right (JInt D1_1to9 [0])
--
-- >>> testparsetheneof parseJInt "39"
-- Right (JInt D3_1to9 [9])
--
-- >>> testparsetheneof parseJInt "393564"
-- Right (JInt D3_1to9 [9,3,5,6,4])
--
-- >>> testparsetheneof parseJInt "0"
-- Right JZero
--
-- >>> isLeft (testparse parseJInt "x")
-- True
--
-- >>> isLeft (testparse parseJInt "")
-- True
parseJInt ::
  (Monad f, CharParsing f) =>
  f JInt
parseJInt =
  asum [
    JZero <$ try (char '0')
  , JInt <$> parseDigit1to9 <*> parsedigitlist
  ]

data E =
  EE
  | Ee
  deriving (Eq, Ord, Show)

-- |
--
-- >>> testparse parseE "e"
-- Right Ee
--
-- >>> testparse parseE "E"
-- Right EE
--
-- >>> testparsetheneof parseE "e"
-- Right Ee
--
-- >>> testparsetheneof parseE "E"
-- Right EE
--
-- >>> isLeft (testparsetheneof parseE "x")
-- True
--
-- >>> testparsethennoteof parseE "ea"
-- Right Ee
--
-- >>> testparsethennoteof parseE "Ea"
-- Right EE
parseE ::
  CharParsing f =>
  f E
parseE =
  asum [
    Ee <$ try (char 'e')
  , EE <$ char 'E'
  ]

newtype Frac =
  Frac
    (NonEmpty Digit)
  deriving (Eq, Ord, Show)


-- |
--
-- >>> testparsetheneof parseFrac "1"
-- Right (Frac (1 :| []))
--
-- >>> testparsetheneof parseFrac "9"
-- Right (Frac (9 :| []))
--
-- >>> testparsetheneof parseFrac "10"
-- Right (Frac (1 :| [0]))
--
-- >>> testparsetheneof parseFrac "39"
-- Right (Frac (3 :| [9]))
--
-- >>> testparsetheneof parseFrac "393564"
-- Right (Frac (3 :| [9,3,5,6,4]))
--
-- >>> testparsetheneof parseFrac "0"
-- Right (Frac (0 :| []))
--
-- >>> testparsetheneof parseFrac "00"
-- Right (Frac (0 :| [0]))
--
-- >>> testparsetheneof parseFrac "01"
-- Right (Frac (0 :| [1]))
--
-- >>> testparsethennoteof parseFrac "01x"
-- Right (Frac (0 :| [1]))
parseFrac ::
  (Monad f, CharParsing f) =>
  f Frac  
parseFrac =
  Frac <$> some1 parsedigit

data Exp =
  Exp {
    _e ::
      E
  , _minusplus ::
     Bool
  , _expdigits ::
     NonEmpty Digit
  }
  deriving (Eq, Ord, Show)

-- |
--
-- >>> testparsethen parseExp "e+10x"
-- Right (Exp {_e = Ee, _minusplus = False, _expdigits = 1 :| [0]},'x')
--
-- >>> testparsethen parseExp "e-0x"
-- Right (Exp {_e = Ee, _minusplus = True, _expdigits = 0 :| []},'x')
--
-- >>> testparsethen parseExp "E-1x"
-- Right (Exp {_e = EE, _minusplus = True, _expdigits = 1 :| []},'x')
parseExp ::
  (Monad f, CharParsing f) =>
  f Exp  
parseExp =
  Exp <$>
    parseE <*>
    asum [False <$ char '+', True <$ char '-'] <*>
    parsedigitlist1

{-
number = [ minus ] int [ frac ] [ exp ]

   decimal-point = %x2E       ; .

   digit1-9 = %x31-39         ; 1-9

   e = %x65 / %x45            ; e E

   exp = e [ minus / plus ] 1*DIGIT

   frac = decimal-point 1*DIGIT

   int = zero / ( digit1-9 *DIGIT )

   minus = %x2D               ; -

   plus = %x2B                ; +

   zero = %x30                ; 0
-}

data Sign =
  Minus
  | Plus
  | Nosign
  deriving (Eq, Ord, Show)

data JNumba =
  JNumba {
    _minus ::
      Bool
  , _numberint ::
      JInt
  , _fracexp :: 
      Maybe (Frac, Maybe Exp)
  }
  deriving (Eq, Ord, Show)

-- |
--
-- >>> testparsethen parseJNumba "3x"
-- Right (JNumba {_minus = False, _numberint = JInt D3_1to9 [], _fracexp = Nothing},'x')
--
-- >>> testparsethen parseJNumba "-3x"
-- Right (JNumba {_minus = True, _numberint = JInt D3_1to9 [], _fracexp = Nothing},'x')
--
-- >>> testparsethen parseJNumba "0x"
-- Right (JNumba {_minus = False, _numberint = JZero, _fracexp = Nothing},'x')
--
-- >>> testparsethen parseJNumba "-0x"
-- Right (JNumba {_minus = True, _numberint = JZero, _fracexp = Nothing},'x')
--
-- >>> testparsethen parseJNumba "3.45x"
-- Right (JNumba {_minus = False, _numberint = JInt D3_1to9 [], _fracexp = Just (Frac (4 :| [5]),Nothing)},'x')
--
-- >>> testparsethen parseJNumba "-3.45x"
-- Right (JNumba {_minus = True, _numberint = JInt D3_1to9 [], _fracexp = Just (Frac (4 :| [5]),Nothing)},'x')
--
-- >>> testparsethen parseJNumba "3.45e+10x"
-- Right (JNumba {_minus = False, _numberint = JInt D3_1to9 [], _fracexp = Just (Frac (4 :| [5]),Just (Exp {_e = Ee, _minusplus = False, _expdigits = 1 :| [0]}))},'x')
--
-- >>> testparsethen parseJNumba "-3.45e-02x"
-- Right (JNumba {_minus = True, _numberint = JInt D3_1to9 [], _fracexp = Just (Frac (4 :| [5]),Just (Exp {_e = Ee, _minusplus = True, _expdigits = 0 :| [2]}))},'x')
parseJNumba ::
  (Monad f, CharParsing f) =>
  f JNumba  
parseJNumba =
  JNumba <$>
    isJust <$> optional (try (char '-')) <*>
    parseJInt <*>
    optional ((,) <$ char '.' <*> parseFrac <*> optional parseExp)
    
