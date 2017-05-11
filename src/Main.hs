module Main where
import Add
import Input
import Remove
import Quiz
import Card
import Tracker
import Text.Printf(printf)
import Display
import System.Environment(getArgs)
import System.Directory(doesFileExist)
import Data.Maybe(isJust)
import Safe(readMay)
import Control.Monad(filterM)
import qualified System.IO.Strict as SIO

data Action = Quiz | Add | Remove | Show | Quit deriving (Show, Eq, Ord, Enum)

instance Display Action where
    display = show

allActions :: [Action]
allActions = [Quiz ..]

getAction :: IO (Maybe Action)
getAction = Input.getUserChoice allActions

runAction :: Maybe Action -> [Card] -> IO ()
runAction (Just Quit) cards   = do
    saveData cards
    return ()
runAction (Just Add) cards    = addLoop cards   >>= mainLoop
runAction (Just Quiz) cards   = quizLoop cards  >>= mainLoop
runAction (Just Remove) cards = removeLoop cards >>= mainLoop
runAction (Just Show) cards   = do
    displayAllDecks cards
    mainLoop cards
runAction Nothing cards       = do
    printf $ "Invalid input" ++ "\n"
    mainLoop cards

{-fileHandle :: IO Handle-}
{-fileHandle = openFile "data.clanki" ReadWriteMode-}

fileName :: String
fileName = "data.clanki"

mainLoop :: [Card] -> IO ()
mainLoop decks = do
    action <- getAction
    runAction action decks

loadData :: IO [Card]
loadData = do
    fileExists <- doesFileExist fileName
    if fileExists
        then do
        x <- SIO.readFile fileName
        return $ read x
        else return []


saveData :: [Card] -> IO ()
saveData decks = writeFile fileName (show decks)

startWithArgs :: [String] -> [Card] -> IO [Card]
startWithArgs args cards
    | null args = return cards
    | "--help" `elem` args || "-h" `elem` args =
        do
            displayHelp
            return cards
    | "--list" `elem` args || "-l" `elem` args =
        do
            displayAllDecks cards
            return cards
    | firstOptionIsNum = do
        let numOfCardsToQuiz = read (head args) :: Int
        quizSomeCards (take numOfCardsToQuiz cards) cards
    | firstOptionIsDeck =
        if secondOptionIsNum
            then do
                let numOfCardsToQuiz = read $ args !! 1
                let deckCards = cardsInDeck (head args) cards
                cardsToQuiz <- filterM shouldQuizCard (take numOfCardsToQuiz deckCards)
                quizSomeCards cardsToQuiz cards
            else do
                cardsToQuiz <- filterM shouldQuizCard (cardsInDeck (head args) cards)
                quizSomeCards cardsToQuiz cards
    | head args == "-add" = do
        let deckName = args !! 1
        let question = args !! 2
        let answer   = args !! 3
        if length args >= 5 && args !! 4 == "-2"
            then return $ cards ++ [newCard question answer deckName] ++ [newCard answer question deckName]
            else return $ cards ++ [newCard question answer deckName]
    | otherwise = return cards
    where
        isDeckName str = hasDeckNamed str cards
        firstOptionIsNum = isJust (readMay (head args) :: Maybe Int)
        firstOptionIsDeck = isDeckName (head args)
        secondOptionIsNum = length args > 1 && isJust (readMay (args !! 1) :: Maybe Int)


displayHelp :: IO ()
displayHelp = do
    printf $ "OPTIONS:" ++ "\n"
    printf $ "--list  -l              List available decks in default directory" ++ "\n"
    printf $ "--stats -s              Show some stats about the decks" ++ "\n"
    printf $ "--help -h               Show this help" ++ "\n"

main :: IO ()
main = do
    cards <- loadData
    args <- getArgs
    newCards <- startWithArgs args cards
    mainLoop newCards
