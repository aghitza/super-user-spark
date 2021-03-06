{-# LANGUAGE DeriveGeneric #-}

module SuperUserSpark.Language.Types where

import Import

import SuperUserSpark.CoreTypes

-- * Cards
type CardName = String

type Source = FilePath

type Destination = FilePath

data Card = Card
    { cardName :: CardName
    , cardContent :: Declaration
    } deriving (Show, Eq, Generic)

instance Validity Card

-- ** Declarations
-- | A declaration in a card
data Declaration
    = SparkOff CardReference -- ^ Spark off another card
    | Deploy Source
             Destination
             (Maybe DeploymentKind) -- ^ Deploy from source to destination
    | IntoDir Directory -- ^ Deploy into a directory
    | OutofDir Directory -- ^ Deploy outof a directory
    | DeployKindOverride DeploymentKind -- ^ Override the deployment kind
    | Alternatives [Directory] -- ^ Provide a list of alternative sources
    | Block [Declaration] -- ^ A scoped block of declarations
    deriving (Show, Eq, Generic)

instance Validity Declaration

-- * Card references
-- | Reference a card by name (inside a file)
newtype CardNameReference =
    CardNameReference CardName
    deriving (Show, Eq, Generic)

instance Validity CardNameReference

-- | Reference a card by the file it is in and therein potentially by a name reference
data CardFileReference =
    CardFileReference FilePath
                      (Maybe CardNameReference)
    deriving (Show, Eq, Generic)

instance Validity CardFileReference

instance Read CardFileReference where
    readsPrec _ fp =
        case length (words fp) of
            1 -> [(CardFileReference fp Nothing, "")]
            2 ->
                let [f, c] = words fp
                in [(CardFileReference f (Just $ CardNameReference c), "")]
            _ -> []

-- | Union card reference
data CardReference
    = CardFile CardFileReference
    | CardName CardNameReference
    deriving (Show, Eq, Generic)

instance Validity CardReference

-- * Card files
data SparkFile = SparkFile
    { sparkFilePath :: Path Abs File
    , sparkFileCards :: [Card]
    } deriving (Show, Eq, Generic)

instance Validity SparkFile
