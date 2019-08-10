port module ManifestMain exposing (main)

import Color exposing (Color)
import Json.Encode
import Pages.Manifest as Manifest
import Pages.Manifest.Category


port generateManifest : Json.Encode.Value -> Cmd msg


main =
    Manifest.generate generateManifest config


config =
    { backgroundColor = Just Color.blue
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = "elm-pages - A statically typed site generator."
    , iarcRatingId = Nothing
    , name = "elm-pages docs"
    , themeColor = Just Color.blue
    , startUrl = Just "/"
    , shortName = Just "elm-pages"
    }