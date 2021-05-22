module Api exposing (routes)

import ApiRoute
import Article
import DataSource
import DataSource.Http
import Html exposing (Html)
import Json.Encode
import OptimizedDecoder as Decode
import Pages
import Route
import Rss
import Secrets
import SiteOld
import Time


routes :
    (Html Never -> String)
    -> List (ApiRoute.Done ApiRoute.Response)
routes htmlToString =
    [ ApiRoute.succeed
        (\userId ->
            DataSource.succeed
                { body =
                    Json.Encode.object
                        [ ( "id", Json.Encode.int userId )
                        , ( "name"
                          , Html.p [] [ Html.text <| "Data for user " ++ String.fromInt userId ]
                                |> htmlToString
                                |> Json.Encode.string
                          )
                        ]
                        |> Json.Encode.encode 2
                }
        )
        |> ApiRoute.literal "users"
        |> ApiRoute.slash
        |> ApiRoute.int
        |> ApiRoute.literal ".json"
        |> ApiRoute.buildTimeRoutes
            (\route ->
                DataSource.succeed
                    [ route 1
                    , route 2
                    , route 3
                    ]
            )
    , ApiRoute.succeed
        (\repoName ->
            DataSource.Http.get
                (Secrets.succeed ("https://api.github.com/repos/dillonkearns/" ++ repoName))
                (Decode.field "stargazers_count" Decode.int)
                |> DataSource.map
                    (\stars ->
                        { body =
                            Json.Encode.object
                                [ ( "repo", Json.Encode.string repoName )
                                , ( "stars", Json.Encode.int stars )
                                ]
                                |> Json.Encode.encode 2
                        }
                    )
        )
        |> ApiRoute.literal "repo"
        |> ApiRoute.slash
        |> ApiRoute.capture
        |> ApiRoute.literal ".json"
        |> ApiRoute.buildTimeRoutes
            (\route ->
                DataSource.succeed
                    [ route "elm-graphql"
                    ]
            )
    , rss
        { siteTagline = SiteOld.tagline
        , siteUrl = SiteOld.canonicalUrl
        , title = "elm-pages Blog"
        , builtAt = Pages.builtAt
        , indexPage = [ "blog" ]
        }
        postsDataSource

    --, ApiRoute.succeed
    --    (DataSource.succeed
    --        { body =
    --            allRoutes
    --                |> List.filterMap identity
    --                |> List.map
    --                    (\route ->
    --                        { path = Route.routeToPath (Just route) |> String.join "/"
    --                        , lastMod = Nothing
    --                        }
    --                    )
    --                |> Sitemap.build { siteUrl = "https://elm-pages.com" }
    --        }
    --    )
    --    |> ApiRoute.literal "sitemap.xml"
    --    |> ApiRoute.singleRoute
    ]


postsDataSource : DataSource.DataSource (List Rss.Item)
postsDataSource =
    Article.allMetadata
        |> DataSource.map
            (List.map
                (\( route, article ) ->
                    { title = article.title
                    , description = article.description
                    , url =
                        Just route
                            |> Route.routeToPath
                            |> String.join "/"
                    , categories = []
                    , author = "Dillon Kearns"
                    , pubDate = Rss.Date article.published
                    , content = Nothing
                    }
                )
            )


rss :
    { siteTagline : String
    , siteUrl : String
    , title : String
    , builtAt : Time.Posix
    , indexPage : List String
    }
    -> DataSource.DataSource (List Rss.Item)
    -> ApiRoute.Done ApiRoute.Response
rss options itemsRequest =
    ApiRoute.succeed
        (itemsRequest
            |> DataSource.map
                (\items ->
                    { body =
                        Rss.generate
                            { title = options.title
                            , description = options.siteTagline
                            , url = options.siteUrl ++ "/" ++ String.join "/" options.indexPage
                            , lastBuildTime = options.builtAt
                            , generator = Just "elm-pages"
                            , items = items
                            , siteUrl = options.siteUrl
                            }
                    }
                )
        )
        |> ApiRoute.literal "blog/feed.xml"
        |> ApiRoute.singleRoute
