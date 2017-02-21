{-# LANGUAGE TemplateHaskell #-}

module SuperUserSpark.Check.TestUtils where

import TestImport

import SuperUserSpark.Bake.Gen ()
import SuperUserSpark.Bake.Types
import SuperUserSpark.Check.Gen ()
import SuperUserSpark.Check.Internal
import SuperUserSpark.Check.Types
import SuperUserSpark.CoreTypes
import SuperUserSpark.Diagnose.Types

-- * Test utils for checkDeployment
shouldBeImpossible' :: DiagnosedDeployment -> Expectation
shouldBeImpossible' dd = checkDeployment dd `shouldSatisfy` impossibleDeployment

shouldBeImpossibleDeployment :: [CheckResult] -> Expectation
shouldBeImpossibleDeployment dd =
    bestResult dd `shouldSatisfy` impossibleDeployment

-- * Test utils for checkSingle
isDirty :: CheckResult -> Bool
isDirty (Dirty _ _ _) = True
isDirty _ = False

isReady :: CheckResult -> Bool
isReady (Ready _) = True
isReady _ = False

isDone :: CheckResult -> Bool
isDone AlreadyDone = True
isDone _ = False

isImpossible :: CheckResult -> Bool
isImpossible (Impossible _) = True
isImpossible _ = False

shouldBeDirty
    :: DiagnosedFp
    -> DiagnosedFp
    -> DeploymentKind
    -> CleanupInstruction
    -> Expectation
shouldBeDirty src dst kind eci =
    case checkSingle src dst kind of
        Dirty _ ins ci -> do
            ci `shouldBe` eci
            let tp = dropTrailingPathSeparator . toFilePath
            case ins of
                CopyFile isrc idst -> do
                    tp isrc `shouldBe` toPath (diagnosedFilePath src)
                    tp idst `shouldBe` toPath (diagnosedFilePath dst)
                    CopyDeployment `shouldBe` kind
                CopyDir isrc idst -> do
                    tp isrc `shouldBe` toPath (diagnosedFilePath src)
                    tp idst `shouldBe` toPath (diagnosedFilePath dst)
                    CopyDeployment `shouldBe` kind
                LinkFile isrc idst -> do
                    tp isrc `shouldBe` toPath (diagnosedFilePath src)
                    tp idst `shouldBe` toPath (diagnosedFilePath dst)
                    LinkDeployment `shouldBe` kind
                LinkDir isrc idst -> do
                    tp isrc `shouldBe` toPath (diagnosedFilePath src)
                    tp idst `shouldBe` toPath (diagnosedFilePath dst)
                    LinkDeployment `shouldBe` kind
        t ->
            expectationFailure $
            unlines
                [ "checkSingle"
                , show src
                , show dst
                , show kind
                , "should be dirty but is"
                , show t
                ]

shouldBeReady :: DiagnosedFp -> DiagnosedFp -> DeploymentKind -> Expectation
shouldBeReady src dst kind = checkSingle src dst kind `shouldSatisfy` isReady

shouldBeDone :: DiagnosedFp -> DiagnosedFp -> DeploymentKind -> Expectation
shouldBeDone src dst kind = checkSingle src dst kind `shouldSatisfy` isDone

shouldBeImpossible :: DiagnosedFp
                   -> DiagnosedFp
                   -> DeploymentKind
                   -> Expectation
shouldBeImpossible src dst kind =
    checkSingle src dst kind `shouldSatisfy` isImpossible

validWith :: Diagnostics -> Gen DiagnosedFp
validWith d = D <$> genValid <*> pure d <*> genValid
