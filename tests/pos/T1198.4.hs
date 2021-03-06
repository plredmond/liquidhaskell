module Term where

{-@ data Tree [sz] @-}
data Tree a =  Node (Tree a) (Tree a)

{-@ measure sz @-}
sz :: Tree a -> Int
sz (Node t1 t2) = 1 + sz  t1 + sz  t2