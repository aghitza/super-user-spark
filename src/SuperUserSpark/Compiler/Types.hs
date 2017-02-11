{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module SuperUserSpark.Compiler.Types where

import Import

import Data.Aeson
       (FromJSON(..), ToJSON(..), Value(..), object, (.:), (.=))
import Text.Parsec as Parsec

import SuperUserSpark.Constants
import SuperUserSpark.CoreTypes
import SuperUserSpark.Language.Types
import SuperUserSpark.PreCompiler.Types

data CompileAssignment = CompileAssignment
    { compileCardReference :: CardFileReference
    , compileSettings :: CompileSettings
    } deriving (Show, Eq, Generic)

data CompileSettings = CompileSettings
    { compileOutput :: Maybe FilePath -- Todo make statically typed
    , compileDefaultKind :: DeploymentKind
    , compileKindOverride :: Maybe DeploymentKind
    } deriving (Show, Eq, Generic)

data Deployment = Put
    { deploymentSources :: [FilePath]
    , deploymentDestination :: FilePath
    , deploymentKind :: DeploymentKind
    } deriving (Eq)

instance Show Deployment where
    show dep = unwords $ srcs ++ [k, dst]
      where
        srcs = map quote $ deploymentSources dep
        k =
            case deploymentKind dep of
                LinkDeployment -> linkKindSymbol
                CopyDeployment -> copyKindSymbol
        dst = quote $ deploymentDestination dep
        quote = (\s -> "\"" ++ s ++ "\"")

instance FromJSON Deployment where
    parseJSON (Object o) =
        Put <$> o .: "sources" <*> o .: "destination" <*> o .: "deployment kind"
    parseJSON _ = mzero

instance ToJSON Deployment where
    toJSON depl =
        object
            [ "sources" .= deploymentSources depl
            , "destination" .= deploymentDestination depl
            , "deployment kind" .= deploymentKind depl
            ]

type CompilerPrefix = [PrefixPart]

data PrefixPart
    = Literal String
    | Alts [String]
    deriving (Show, Eq)

data CompilerState = CompilerState
    { stateDeploymentKindLocalOverride :: Maybe DeploymentKind
    , stateInto :: Directory
    , stateOutof_prefix :: CompilerPrefix
    } deriving (Show, Eq)

type ImpureCompiler = ExceptT CompileError (ReaderT CompileSettings IO)

type PureCompiler = ExceptT CompileError (ReaderT CompileSettings Identity)

type InternalCompiler = StateT CompilerState (WriterT ([Deployment], [CardReference]) PureCompiler)

data CompileError
    = ParseError Parsec.ParseError
    | PreCompileErrors [PreCompileError]
    | DuringCompilationError String
    deriving (Show, Eq, Generic)
