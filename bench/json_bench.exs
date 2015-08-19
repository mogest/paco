defmodule Paco.Benchmark.JSON do
  use Benchfella

  @small ~S"""
  {"menu": {
    "id": "file",
    "value": "File",
    "popup": {
      "menuitem": [
        {"value": "New", "onclick": "CreateNewDoc()"},
        {"value": "Open", "onclick": "OpenDoc()"},
        {"value": "Close", "onclick": "CloseDoc()"}
      ]
    }
  }}
  """

  @medium ~S"""
  {
    "statuses": [
      {
        "metadata": {
          "result_type": "recent",
          "iso_language_code": "ja"
        },
        "created_at": "Sun Aug 31 00:29:15 +0000 2014",
        "id": 505874924095815700,
        "id_str": "505874924095815681",
        "text": "@aym0566x \n\n名前:前田あゆみ\n第一印象:なんか怖っ！\n今の印象:とりあえずキモい。噛み合わない\n好きなところ:ぶすでキモいとこ😋✨✨\n思い出:んーーー、ありすぎ😊❤️\nLINE交換できる？:あぁ……ごめん✋\nトプ画をみて:照れますがな😘✨\n一言:お前は一生もんのダチ💖",
        "source": "<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>",
        "truncated": false,
        "in_reply_to_status_id": null,
        "in_reply_to_status_id_str": null,
        "in_reply_to_user_id": 866260188,
        "in_reply_to_user_id_str": "866260188",
        "in_reply_to_screen_name": "aym0566x",
        "user": {
          "id": 1186275104,
          "id_str": "1186275104",
          "name": "AYUMI",
          "screen_name": "ayuu0123",
          "location": "",
          "description": "元野球部マネージャー❤︎…最高の夏をありがとう…❤︎",
          "url": null,
          "entities": {
            "description": {
              "urls": []
            }
          },
          "protected": false,
          "followers_count": 262,
          "friends_count": 252,
          "listed_count": 0,
          "created_at": "Sat Feb 16 13:40:25 +0000 2013",
          "favourites_count": 235,
          "utc_offset": null,
          "time_zone": null,
          "geo_enabled": false,
          "verified": false,
          "statuses_count": 1769,
          "lang": "en",
          "contributors_enabled": false,
          "is_translator": false,
          "is_translation_enabled": false,
          "profile_background_color": "C0DEED",
          "profile_background_image_url": "http://abs.twimg.com/images/themes/theme1/bg.png",
          "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme1/bg.png",
          "profile_background_tile": false,
          "profile_image_url": "http://pbs.twimg.com/profile_images/497760886795153410/LDjAwR_y_normal.jpeg",
          "profile_image_url_https": "https://pbs.twimg.com/profile_images/497760886795153410/LDjAwR_y_normal.jpeg",
          "profile_banner_url": "https://pbs.twimg.com/profile_banners/1186275104/1409318784",
          "profile_link_color": "0084B4",
          "profile_sidebar_border_color": "C0DEED",
          "profile_sidebar_fill_color": "DDEEF6",
          "profile_text_color": "333333",
          "profile_use_background_image": true,
          "default_profile": true,
          "default_profile_image": false,
          "following": false,
          "follow_request_sent": false,
          "notifications": false
        },
        "geo": null,
        "coordinates": null,
        "place": null,
        "contributors": null,
        "retweet_count": 0,
        "favorite_count": 0,
        "entities": {
          "hashtags": [],
          "symbols": [],
          "urls": [],
          "user_mentions": [
            {
              "screen_name": "aym0566x",
              "name": "前田あゆみ",
              "id": 866260188,
              "id_str": "866260188",
              "indices": [
                0,
                9
              ]
            }
          ]
        },
        "favorited": false,
        "retweeted": false,
        "lang": "ja"
      }
    ]
  }
  """

  bench "small" do
    {:ok, _} = Paco.Parser.JSON.parse(@small)
  end

  bench "medium" do
    {:ok, _} = Paco.Parser.JSON.parse(@medium)
  end
end
