module Bookkeeper.Internal.Types where

import Data.Kind (Type)
import GHC.Generics
import GHC.TypeLits (Symbol, KnownSymbol, TypeError, ErrorMessage(..), CmpSymbol)
import GHC.OverloadedLabels
import Data.Default.Class (Default(..))
import Control.Monad.Identity

------------------------------------------------------------------------------
-- :=>
------------------------------------------------------------------------------

data (a :: Symbol) :=> (b :: k)

------------------------------------------------------------------------------
-- Key
------------------------------------------------------------------------------

-- | 'Key' is simply a proxy. You will usually not need to create one
-- directly, as it is generated by the OverlodadedLabels magic.
data Key (a :: Symbol) = Key
  deriving (Eq, Show, Read, Generic)

instance (s ~ s') => IsLabel s (Key s') where
  fromLabel _ = Key

------------------------------------------------------------------------------
-- Book
------------------------------------------------------------------------------

data Book' :: (k -> Type) -> [Type] -> Type where
  BNil :: Book' f '[]
  BCons :: Key key -> f a -> Book' f as -> Book' f (k :=> a ': as)

instance Eq (Book' f '[]) where
  _ == _ = True

instance (Eq (f val), Eq (Book' f xs)) => Eq (Book' f ((field :=> val) ': xs)) where
  BCons _ value1 rest1 == BCons _ value2 rest2
    = value1 == value2 && rest1 == rest2

instance Monoid (Book' Identity '[]) where
  mempty = emptyBook
  _ `mappend` _ = emptyBook

instance Default (Book' Identity '[]) where
  def = emptyBook

instance ( Default (Book' f xs)
         , Default (f v)
         ) => Default (Book' f ((k :=> v) ': xs)) where
  def = BCons Key def def

-- | A book with no records. You'll usually want to use this to construct
-- books.
emptyBook :: Book' Identity '[]
emptyBook = BNil

{-

instance ShowHelper (Book' a) => Show (Book' a) where
  show x = "Book {" <> intercalate ", " (go <$> showHelper x) <> "}"
    where
      go (k, v) = k <> " = " <> v

class ShowHelper a where
  showHelper :: a -> [(String, String)]

instance ShowHelper (Book' '[]) where
  showHelper _ = []

instance ( ShowHelper (Book' xs)
         , KnownSymbol k
         , Show v
         ) => ShowHelper (Book' ((k :=> v) ': xs)) where
  showHelper (Book (Map.Ext k v rest)) = (show k, show v):showHelper (Book rest)

-}

-- * Generics

{-
class FromGeneric a book | a -> book where
  fromGeneric :: a x -> Book' Identity book

instance FromGeneric cs book => FromGeneric (D1 m cs) book where
  fromGeneric (M1 xs) = fromGeneric xs

instance FromGeneric cs book => FromGeneric (C1 m cs) book where
  fromGeneric (M1 xs) = fromGeneric xs

instance (v ~ Book' Identity '[name :=> t])
  => FromGeneric (S1 ('MetaSel ('Just name) p s l) (Rec0 t)) v where
  fromGeneric (M1 (K1 t)) = (Key =: t) emptyBook

instance
  ( FromGeneric l lbook
  , FromGeneric r rbook
  , Map.Unionable lbook rbook
  , book ~ Map.Union lbook rbook
  ) => FromGeneric (l :*: r) book where
  fromGeneric (l :*: r)
    = Book $ Map.union (getBook (fromGeneric l)) (getBook (fromGeneric r))

type family Expected a where
  Expected (l :+: r) = TypeError ('Text "Cannot convert sum types into Books")
  Expected U1        = TypeError ('Text "Cannot convert non-record types into Books")

instance (book ~ Expected (l :+: r)) => FromGeneric (l :+: r) book where
  fromGeneric = error "impossible"

instance (book ~ Expected U1) => FromGeneric U1 book where
  fromGeneric = error "impossible"

  -}