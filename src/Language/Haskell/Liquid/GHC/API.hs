-- | This module re-exports a bunch of the GHC API.

{-# LANGUAGE CPP #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE BangPatterns #-}

module Language.Haskell.Liquid.GHC.API (
    module Ghc

-- Specific imports for 8.6.5
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,8,1,0)
  , pattern Bndr
  , pattern LitString
  , pattern LitFloat
  , pattern LitDouble
  , pattern LitChar
  , VarBndr
#endif
#endif

-- Specific imports for 8.6.5 and 8.8.x
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)
  , AnonArgFlag(..)
  , pattern FunTy
  , pattern AnonTCB
  , ft_af, ft_arg, ft_res
  , bytesFS
  , mkFunTy
  , isEvVarType
  , isEqPrimPred
#endif
#endif

  , tyConRealArity
  , dataConExTyVars

-- Specific imports for 8.8.x
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,8,1,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)
  , isEqPred
#endif
#endif

  ) where

import Avail          as Ghc
import GHC            as Ghc hiding (Warning)
import ConLike        as Ghc
import Var            as Ghc
import Module         as Ghc
import DataCon        as Ghc
import TysWiredIn     as Ghc
import BasicTypes     as Ghc
import CoreSyn        as Ghc hiding (AnnExpr, AnnExpr' (..), AnnRec, AnnCase)
import NameSet        as Ghc
import InstEnv        as Ghc
import Literal        as Ghc
import Class          as Ghc
import Unique         as Ghc
import RdrName        as Ghc
import SrcLoc         as Ghc
import Name           as Ghc hiding (varName)
import TysPrim        as Ghc
import HscTypes       as Ghc
import HscMain        as Ghc
import Id             as Ghc hiding (lazySetIdInfo, setIdExported, setIdNotExported)
import ErrUtils       as Ghc
import DynFlags       as Ghc

--
-- Compatibility layer for different GHC versions.
--

--
-- Specific imports for GHC 8.6.5
--
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,8,1,0)

import qualified Literal as Lit
import FastString        as Ghc hiding (bytesFS, LitString)
import TcType            as Ghc hiding (typeKind, mkFunTy)
import Type              as Ghc hiding (typeKind, mkFunTy)
import qualified Var     as Var
import qualified GHC.Real

#endif
#endif

--
-- Specific imports for GHC 8.6.5 & 8.8.x
--
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)

import                   Binary
import                   Data.ByteString (ByteString)
import                   Data.Data (Data)
import                   Outputable
import Kind              as Ghc
import TyCoRep           as Ghc hiding (Type (FunTy), mkFunTy)
import TyCon             as Ghc hiding (TyConBndrVis(AnonTCB))
import qualified TyCoRep as Ty
import qualified TyCon   as Ty

#endif
#endif

--
-- Specific imports for 8.8.x
--
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,8,1,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)

import FastString           as Ghc hiding (bytesFS)
import TcType               as Ghc hiding (typeKind, mkFunTy, isEqPred)
import Type                 as Ghc hiding (typeKind, mkFunTy, isEvVarType, isEqPred)
import qualified Type       as Ghc (isEvVarType)
import qualified PrelNames  as Ghc
import Data.Foldable        (asum)

#endif
#endif

--
-- Specific imports for GHC 8.10
--
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,10,0,0)
import Type           as Ghc hiding (typeKind , isPredTy)
import TyCon          as Ghc
import TcType         as Ghc
import TyCoRep        as Ghc
import FastString     as Ghc
import Predicate      as Ghc (getClassPredTys_maybe, isEvVarType)
import Data.Foldable  (asum)
#endif
#endif

--
-- Compat shim for GHC 8.6.5

#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,8,1,0)
pattern LitString :: ByteString -> Lit.Literal
pattern LitString bs <- Lit.MachStr bs where
    LitString bs = Lit.MachStr bs

pattern LitFloat :: GHC.Real.Ratio Integer -> Lit.Literal
pattern LitFloat f <- Lit.MachFloat f where
    LitFloat f = Lit.MachFloat f

pattern LitDouble :: GHC.Real.Ratio Integer -> Lit.Literal
pattern LitDouble d <- Lit.MachDouble d where
    LitDouble d = Lit.MachDouble d

pattern LitChar :: Char -> Lit.Literal
pattern LitChar c <- Lit.MachChar c where
    LitChar c = Lit.MachChar c

pattern Bndr :: var -> argf -> Var.TyVarBndr var argf
pattern Bndr var argf <- TvBndr var argf where
    Bndr var argf = TvBndr var argf

type VarBndr = TyVarBndr

isEqPrimPred :: Type -> Bool
isEqPrimPred = Ghc.isPredTy

-- See NOTE [isEvVarType].
isEvVarType :: Type -> Bool
isEvVarType = Ghc.isPredTy

tyConRealArity :: TyCon -> Int
tyConRealArity = tyConArity

#endif
#endif

--
-- Compat shim for GHC-8.6.5 and GHC-8.8.x
--
#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,6,5,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)

-- | The non-dependent version of 'ArgFlag'.

-- Appears here partly so that it's together with its friend ArgFlag,
-- but also because it is used in IfaceType, rather early in the
-- compilation chain
-- See Note [AnonArgFlag vs. ForallVisFlag]
data AnonArgFlag
  = VisArg    -- ^ Used for @(->)@: an ordinary non-dependent arrow.
              --   The argument is visible in source code.
  | InvisArg  -- ^ Used for @(=>)@: a non-dependent predicate arrow.
              --   The argument is invisible in source code.
  deriving (Eq, Ord, Data)

instance Outputable AnonArgFlag where
  ppr VisArg   = text "[vis]"
  ppr InvisArg = text "[invis]"

instance Binary AnonArgFlag where
  put_ bh VisArg   = putByte bh 0
  put_ bh InvisArg = putByte bh 1

  get bh = do
    h <- getByte bh
    case h of
      0 -> return VisArg
      _ -> return InvisArg

bytesFS :: FastString -> ByteString
bytesFS = fastStringToByteString

mkFunTy :: AnonArgFlag -> Type -> Type -> Type
mkFunTy _ = Ty.FunTy

pattern FunTy :: AnonArgFlag -> Type -> Type -> Type
pattern FunTy { ft_af, ft_arg, ft_res } <- ((VisArg,) -> (ft_af, Ty.FunTy ft_arg ft_res)) where
    FunTy _ft_af ft_arg ft_res = Ty.FunTy ft_arg ft_res

pattern AnonTCB :: AnonArgFlag -> Ty.TyConBndrVis
pattern AnonTCB af <- ((VisArg,) -> (af, Ty.AnonTCB)) where
    AnonTCB _af = Ty.AnonTCB

#endif

-- Compat shim for GHC 8.8.x

#ifdef MIN_VERSION_GLASGOW_HASKELL
#if MIN_VERSION_GLASGOW_HASKELL(8,8,1,0) && !MIN_VERSION_GLASGOW_HASKELL(8,10,1,0)

isEqPrimPred :: Type -> Bool
isEqPrimPred ty
  | Just tc <- tyConAppTyCon_maybe ty
  = tc `hasKey` Ghc.eqPrimTyConKey || tc `hasKey` Ghc.eqReprPrimTyConKey
  | otherwise
  = False

isEqPred :: Type -> Bool
isEqPred ty
  | Just tc <- tyConAppTyCon_maybe ty
  , Just cls <- tyConClass_maybe tc
  = cls `hasKey` Ghc.eqTyConKey || cls `hasKey` Ghc.heqTyConKey
  | otherwise
  = False

-- See NOTE [isEvVarType].
isEvVarType :: Type -> Bool
isEvVarType = Ghc.isEvVarType

#endif
#endif

{- | [NOTE:tyConRealArity]

The semantics of 'tyConArity' changed between GHC 8.6.5 and GHC 8.10, mostly due to the
Visible Dependent Quantification (VDQ). As a result, given the following:

data family EntityField record :: * -> *

Calling `tyConArity` on this would yield @2@ for 8.6.5 but @1@ an 8.10, so we try to backport
the old behaviour in 8.10 by \"looking\" at the 'Kind' of the input 'TyCon' and trying to recursively
split the type apart with either 'splitFunTy_maybe' or 'splitForAllTy_maybe'.

-}

{- | [NOTE:isEvVarType]

For GHC < 8.8.1 'isPredTy' is effectively the same as the new 'isEvVarType', which covers the cases
for coercion types and \"normal\" type coercions. The 8.6.5 version of 'isPredTy' had a special case to
handle a 'TyConApp' in the case of type equality (i.e. ~ ) which was removed in the implementation
for 8.8.1, which essentially calls 'tcIsConstraintKind' straight away.
-}

--
-- Support for GHC >= 8.8
--

#if MIN_VERSION_GLASGOW_HASKELL(8,8,1,0)

-- See NOTE [tyConRealArity].
tyConRealArity :: TyCon -> Int
tyConRealArity tc = go 0 (tyConKind tc)
  where
    go :: Int -> Kind -> Int
    go !acc k =
      case asum [fmap snd (splitFunTy_maybe k), fmap snd (splitForAllTy_maybe k)] of
        Nothing -> acc
        Just ks -> go (acc + 1) ks

dataConExTyVars :: DataCon -> [TyVar]
dataConExTyVars = dataConExTyCoVars

#endif

--
-- End of compatibility shim.
--
#endif
