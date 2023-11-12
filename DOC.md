# API Documentation

## Authentication

To authenticate user an `Authorization` header with a token value must be passed in every request to the API like this:
```
authorization: Bearer 7dWR/dflC1F31NCrsavT
```

In case the token value is invalid a `403 Forbidden` with text `invalid token` will be returned in response *kept for compatibility, should be replaced with unified JSON response*.

In case the user can't be authenticated with the provided token (e.g. he is banned) the following JSON response is returned with `403 Forbidden` status code:
```json
{"success": false, "error": "banned", "reason": "This user account was banned"}
```



## Endpoints


  * [Web.AreaNotificationController](#web-areanotificationcontroller)
    * [create_business_area_notification](#web-areanotificationcontroller-create_business_area_notification)
    * [delete_business_area_notification](#web-areanotificationcontroller-delete_business_area_notification)
    * [list_business_area_notifications](#web-areanotificationcontroller-list_business_area_notifications)
  * [Web.BusinessAccounts.FollowersController](#web-businessaccounts-followerscontroller)
    * [history](#web-businessaccounts-followerscontroller-history)
  * [Web.BusinessAccounts.StatsController](#web-businessaccounts-statscontroller)
    * [post_views](#web-businessaccounts-statscontroller-post_views)
    * [post_stats](#web-businessaccounts-statscontroller-post_stats)
    * [stats](#web-businessaccounts-statscontroller-stats)
  * [Web.ChatController](#web-chatcontroller)
    * [add_member](#web-chatcontroller-add_member)
  * [Web.CovidController](#web-covidcontroller)
    * [list_by_country](#web-covidcontroller-list_by_country)
    * [list_by_region](#web-covidcontroller-list_by_region)
  * [Web.DropchatController](#web-dropchatcontroller)
    * [user_stream_recordings](#web-dropchatcontroller-user_stream_recordings)
    * [remove_stream_recordings](#web-dropchatcontroller-remove_stream_recordings)
    * [dropchat_list](#web-dropchatcontroller-dropchat_list)
  * [Web.FollowingController](#web-followingcontroller)
    * [index](#web-followingcontroller-index)
    * [index_followers](#web-followingcontroller-index_followers)
    * [user_followers](#web-followingcontroller-user_followers)
  * [Web.InterestController](#web-interestcontroller)
    * [index](#web-interestcontroller-index)
    * [categories](#web-interestcontroller-categories)
  * [API /api/notifications](#api-api-notifications)
    * [index](#api-api-notifications-index)
  * [Web.PostController](#web-postcontroller)
    * [show](#web-postcontroller-show)
    * [create](#web-postcontroller-create)
    * [delete](#web-postcontroller-delete)
    * [update](#web-postcontroller-update)
    * [show](#web-postcontroller-show)
    * [list_nearby](#web-postcontroller-list_nearby)
    * [list_business_posts](#web-postcontroller-list_business_posts)
  * [Web.TokenController](#web-tokencontroller)
    * [create_token](#web-tokencontroller-create_token)
  * [Web.UserController](#web-usercontroller)
    * [show_business_account](#web-usercontroller-show_business_account)

## Web.AreaNotificationController
### <a id=web-areanotificationcontroller-create_business_area_notification></a>create_business_area_notification
#### create_business_area_notification/2 creates area notification with empty logo and image
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2391/area_notifications
* __Request headers:__
```
authorization: Bearer gjrirWqzIqIwDvbkACbo
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "",
  "location": [
    30.0,
    76.6
  ],
  "logo": "",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA6XXnRhU_boAABzB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "business": {
    "avatar": "http://robohash.org/set_set2/bgset_bg2/13AFcnjxYm",
    "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/13AFcnjxYm",
    "first_name": "Camilla",
    "id": 2391,
    "last_name": "Fisher",
    "username": "business-alfreda_feest-67"
  },
  "categories": null,
  "expires_at": "2038-01-01T01:01:01.000000Z",
  "id": 58,
  "image_url": "",
  "inserted_at": "2022-10-30T10:10:25.681135Z",
  "linked_post_id": null,
  "location": {
    "coordinates": [
      30.0,
      76.6
    ],
    "crs": {
      "properties": {
        "name": "EPSG:4326"
      },
      "type": "name"
    },
    "type": "Point"
  },
  "logo_url": "",
  "max_age": null,
  "message": "Message",
  "min_age": null,
  "owner": {
    "avatar": "http://robohash.org/set_set2/bgset_bg2/4SqpDFKmVfh9gC6y",
    "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/4SqpDFKmVfh9gC6y",
    "first_name": "Elroy",
    "id": 2395,
    "last_name": "Jacobs",
    "username": "brennan_johns-38"
  },
  "radius": 123.456,
  "sex": null,
  "title": "Title"
}
```

#### create_business_area_notification/2 returns error when image or logo media key is invalid
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2099/area_notifications
* __Request headers:__
```
authorization: Bearer JctWPz8NWoQ/O10A+2p1
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "invalid",
  "location": [
    30.0,
    76.6
  ],
  "logo": "",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA4_fAqhcBpwAAB1M
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "reason": {
    "image_media_key": [
      "does not exist"
    ]
  },
  "success": false
}
```

#### create_business_area_notification/2 returns error when image or logo media key is invalid
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2099/area_notifications
* __Request headers:__
```
authorization: Bearer JctWPz8NWoQ/O10A+2p1
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "",
  "location": [
    30.0,
    76.6
  ],
  "logo": "invalid",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5AoxXhcBpwAAB2M
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "reason": {
    "logo_media_key": [
      "does not exist"
    ]
  },
  "success": false
}
```

#### create_business_area_notification/2 returns error when categories are invalid
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2136/area_notifications
* __Request headers:__
```
authorization: Bearer gYhlsCVFphDX9z6Tlo4e
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "categories": [
    "sports",
    "art"
  ],
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "",
  "location": [
    30.0,
    76.6
  ],
  "logo": "",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5Ly2ihwrJ4AABYJ
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "error": "invalid_categories",
  "reason": "Invalid categories: sports, art",
  "success": false
}
```

#### create_business_area_notification/2 returns error when categories are invalid
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2136/area_notifications
* __Request headers:__
```
authorization: Bearer gYhlsCVFphDX9z6Tlo4e
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "",
  "location": [
    30.0,
    76.6
  ],
  "logo": "invalid",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5Ngq3BwrJ4AABNI
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "reason": {
    "logo_media_key": [
      "does not exist"
    ]
  },
  "success": false
}
```

#### create_business_area_notification/2 returns error when user is not a member
##### Request
* __Method:__ POST
* __Path:__ /api/businessAccounts/2299/area_notifications
* __Request headers:__
```
authorization: Bearer Dg3B8vKupYSjT9BymfsM
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "expires_at": "2038-01-01 01:01:01Z",
  "image": "",
  "location": [
    30.0,
    76.6
  ],
  "logo": "",
  "message": "Message",
  "radius": 123.456,
  "title": "Title"
}
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA6B3uog8SPYAABIG
x-version: f30c61431aa2
```
* __Response body:__
```json

```

### <a id=web-areanotificationcontroller-delete_business_area_notification></a>delete_business_area_notification
#### delete_business_area_notification/2 deletes area notification when user is a business account admin
##### Request
* __Method:__ DELETE
* __Path:__ /api/businessAccounts/2368/area_notifications/57
* __Request headers:__
```
authorization: Bearer 8noVuqjySybVZYgK812E
```

##### Response
* __Status__: 204
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA6S9hkDVi1YAABXK
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete_business_area_notification/2 deletes area notification when user is a business account owner
##### Request
* __Method:__ DELETE
* __Path:__ /api/businessAccounts/2187/area_notifications/50
* __Request headers:__
```
authorization: Bearer VOepKUSh4SjgJaCw+4k5
```

##### Response
* __Status__: 204
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5kXbEhJJMsAABVK
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete_business_area_notification/2 returns error when user is a member of the business account but not the notification's owner
##### Request
* __Method:__ DELETE
* __Path:__ /api/businessAccounts/2276/area_notifications/55
* __Request headers:__
```
authorization: Bearer ksTLcZ0YDidmXao90daJ
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA575UBiyLaEAABrF
x-version: f30c61431aa2
```
* __Response body:__
```json

```

### <a id=web-areanotificationcontroller-list_business_area_notifications></a>list_business_area_notifications
#### list_business_area_notifications/2 returns pages of page_size items
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/2147/area_notifications
* __Request headers:__
```
authorization: Bearer x0tU8W6TfG4Ca8upkD/A
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "page": 2,
  "page_size": 1
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5bQI_g-47MAABEG
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "entries": [
    {
      "business": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/xYQRD4E52ufI",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/xYQRD4E52ufI",
        "first_name": "Miguel",
        "id": 2147,
        "last_name": "Cassin",
        "username": "business-krista2017-11"
      },
      "categories": null,
      "expires_at": null,
      "id": 47,
      "image_url": "",
      "inserted_at": "2022-10-30T10:10:25.000000Z",
      "linked_post_id": null,
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "logo_url": "",
      "max_age": null,
      "message": "Nostrum!",
      "min_age": null,
      "owner": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/aUM8Y31i0xZ9LDt",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/aUM8Y31i0xZ9LDt",
        "first_name": "Brycen",
        "id": 2153,
        "last_name": "Morar",
        "username": "cydney2093-91"
      },
      "radius": 5475.0,
      "sex": null,
      "title": "nobis"
    }
  ],
  "page": 2,
  "page_size": 1
}
```

## Web.BusinessAccounts.FollowersController
### <a id=web-businessaccounts-followerscontroller-history></a>history
#### GET history returns business followers history
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1011/followers_history
* __Request headers:__
```
authorization: Bearer TRlsG9MZnsrVkvIaho4t
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAvU8FMDF00oAAAlI
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "history": [
    {
      "count": 1,
      "date": "2000-01-01"
    },
    {
      "count": 2,
      "date": "2020-06-06"
    },
    {
      "count": 1,
      "date": "2021-01-25"
    }
  ]
}
```

## Web.BusinessAccounts.StatsController
### <a id=web-businessaccounts-statscontroller-post_views></a>post_views
#### GET post_views returns post views stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1059/stats/posts/2/views
* __Request headers:__
```
authorization: Bearer GKuDXRcAtSFMfIk6FIsX
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyCuSehuG1AAAA5H
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "views": [
    {
      "count": 1,
      "location": {
        "coordinates": [
          37.6155599,
          55.75221998
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      }
    },
    {
      "count": 2,
      "location": {
        "coordinates": [
          -73.93524187,
          40.73060998
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      }
    }
  ]
}
```

#### GET post_views returns 403 for non member
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1073/stats/posts/1/views
* __Request headers:__
```
authorization: Bearer dFxKClccninAHbx6gMRt
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyQHTHA_cr8AAAtI
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### GET post_views returns error when can't fetch stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1068/stats/posts/1/views
* __Request headers:__
```
authorization: Bearer Yz+H/BFuHDboBwNapkcO
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyKgxzCyA_YAAA6H
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "error": "some_error",
  "reason": "some_error",
  "success": false
}
```

### <a id=web-businessaccounts-statscontroller-post_stats></a>post_stats
#### GET post_stats returns post stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1092/stats/posts/2/stats
* __Request headers:__
```
authorization: Bearer i2dWDJqpMqDwbX8qv1wQ
```

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAybbtah_aCMAAAxJ
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "total_views": 3,
  "unique_views": 3,
  "views_by_city": [
    {
      "city": "New York",
      "country": "USA",
      "unique_views": 2
    },
    {
      "city": "Moscow",
      "country": "Russia",
      "unique_views": 1
    }
  ],
  "views_by_sex": [
    {
      "sex": "F",
      "unique_views": 1
    },
    {
      "sex": "M",
      "unique_views": 2
    }
  ]
}
```

#### GET post_stats returns 403 for non member
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1062/stats/posts/1/stats
* __Request headers:__
```
authorization: Bearer SA8vH/Q5IBf312HzdvLk
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyGWX_gV5TAAABDK
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### GET post_stats returns error when can't fetch stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1087/stats/posts/1/stats
* __Request headers:__
```
authorization: Bearer /086jvHZhZH3fawO8yM1
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyYslaBlqPkAAA5E
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "error": "some_error",
  "reason": "some_error",
  "success": false
}
```

### <a id=web-businessaccounts-statscontroller-stats></a>stats
#### GET stats returns business stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1050/stats
* __Request headers:__
```
authorization: Bearer dxBz9H4xDJJXmorVKmoO
```

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAx7qy-C-1icAAA4H
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "total_views": 3,
  "unique_views": 3,
  "viewed_posts": 1,
  "views_by_city": [
    {
      "city": "New York",
      "country": "USA",
      "unique_views": 2
    },
    {
      "city": "Moscow",
      "country": "Russia",
      "unique_views": 1
    }
  ],
  "views_by_sex": [
    {
      "sex": "F",
      "unique_views": 1
    },
    {
      "sex": "M",
      "unique_views": 2
    }
  ]
}
```

#### GET stats returns 403 for non member
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1054/stats
* __Request headers:__
```
authorization: Bearer NqR2KLlCsiMDARDAyrHT
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAx_n9Hg2XiQAAAvJ
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### GET stats returns error when can't fetch stats
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/1081/stats
* __Request headers:__
```
authorization: Bearer FmMISlJh3G0DHrGdaZxY
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAyU9S9Be7qEAAAwJ
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "error": "some_error",
  "reason": "some_error",
  "success": false
}
```

## Web.ChatController
### <a id=web-chatcontroller-add_member></a>add_member
#### add_member add moderator to dropchat
##### Request
* __Method:__ PUT
* __Path:__ /api/rooms/171/member/1531?role=moderator
* __Request headers:__
```
authorization: Bearer DJlyK45v6qwxFS7QYcHG
```

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA2B94_iZjU0AAA4I
x-version: f30c61431aa2
```
* __Response body:__
```json

```

## Web.CovidController
### <a id=web-covidcontroller-list_by_country></a>list_by_country
#### list_by_country/2 returns cases data
##### Request
* __Method:__ GET
* __Path:__ /api/covid/cases/by_country
* __Request headers:__
```
authorization: Bearer y9K/KWcsJsLVkDcVCXHe
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBhw9xSBBpTEAADAB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "cases": [
    {
      "active_cases": 6731,
      "cases": 81250,
      "country": "China",
      "deaths": 3253,
      "location": {
        "coordinates": [
          39.913818,
          116.363625
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 71266,
      "region": "",
      "source_url": ""
    },
    {
      "active_cases": 33190,
      "cases": 41035,
      "country": "Italy",
      "deaths": 3405,
      "location": {
        "coordinates": [
          41.902782,
          12.496366
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 4440,
      "region": "",
      "source_url": ""
    },
    {
      "active_cases": 13924,
      "cases": 14250,
      "country": "United States of America",
      "deaths": 205,
      "location": {
        "coordinates": [
          37.0902405,
          -95.7128906
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 121,
      "region": "",
      "source_url": ""
    }
  ],
  "info": {
    "enabled": true,
    "info": "<h1>Useful COVID info</h1>"
  },
  "updated_at": "2020-03-20T00:00:00.000000Z",
  "worldwide": {
    "active_cases": 53845,
    "cases": 136535,
    "country": "",
    "deaths": 6863,
    "location": {
      "coordinates": [
        0,
        0
      ],
      "crs": {
        "properties": {
          "name": "EPSG:4326"
        },
        "type": "name"
      },
      "type": "Point"
    },
    "population": 0,
    "recoveries": 75827,
    "region": "",
    "source_url": ""
  }
}
```

### <a id=web-covidcontroller-list_by_region></a>list_by_region
#### list_by_region/2 returns cases data
##### Request
* __Method:__ GET
* __Path:__ /api/covid/cases/by_region
* __Request headers:__
```
authorization: Bearer L8jJsjKzWrZzT9uNrCzJ
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBh1LVPDaP9sAADFB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "cases": [
    {
      "active_cases": 0,
      "cases": 0,
      "country": "USA",
      "deaths": 0,
      "location": {
        "coordinates": [
          39.971889000000004,
          -90.71462349999999
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 0,
      "region": "IL, Brown County",
      "source_url": ""
    },
    {
      "active_cases": 1,
      "cases": 1,
      "country": "USA",
      "deaths": 0,
      "location": {
        "coordinates": [
          40.139787999999996,
          -88.19621000000001
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 0,
      "region": "IL, Champaign County",
      "source_url": ""
    },
    {
      "active_cases": 250,
      "cases": 250,
      "country": "USA",
      "deaths": 0,
      "location": {
        "coordinates": [
          12.104873978005386,
          15.06717673331957
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "population": 0,
      "recoveries": 0,
      "region": "NJ",
      "source_url": ""
    }
  ],
  "updated_at": "2020-03-20T00:00:00.000000Z"
}
```

## Web.DropchatController
### <a id=web-dropchatcontroller-user_stream_recordings></a>user_stream_recordings
#### user_stream_recordings with valid params
##### Request
* __Method:__ GET
* __Path:__ /api/stream_recordings?page_size=5&user_id=1161
* __Request headers:__
```
authorization: Bearer ewg24lxaXPXin0mgNOFS
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzMbd5DrzlUAABFK
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "admin": null,
      "channel_name": "j+f52K/Miq:UMDB6ZNs",
      "flags": {},
      "id": 4,
      "inserted_at": "2022-10-30T10:10:23",
      "live_audience_count": 0,
      "peak_audience_count": 0,
      "reactions_count": {
        "dislike": 0,
        "like": 0
      },
      "recording": {
        "status": "finished",
        "urls": [
          "https://test-bucket.aws/sid_channel_name.m3u8"
        ]
      },
      "speakers": [],
      "status": "finished",
      "title": "Sed!"
    }
  ],
  "page_number": 1,
  "page_size": 5,
  "total_entries": 1,
  "total_pages": 1
}
```

### <a id=web-dropchatcontroller-remove_stream_recordings></a>remove_stream_recordings
#### remove_stream_recordings removes stream recordings
##### Request
* __Method:__ DELETE
* __Path:__ /api/stream_recordings/3
* __Request headers:__
```
authorization: Bearer myf8mHN1s/PH1fMEtL3P
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzIxPqBUiOkAABEK
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "success": true
}
```

#### remove_stream_recordings returns 403 for non admin
##### Request
* __Method:__ DELETE
* __Path:__ /api/stream_recordings/5
* __Request headers:__
```
authorization: Bearer 3wqluLomIlI2fQHlsugz
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzX4WMB99NEAAAvI
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "success": false
}
```

### <a id=web-dropchatcontroller-dropchat_list></a>dropchat_list
#### dropchat_list with valid params
##### Request
* __Method:__ POST
* __Path:__ /api/dropchat_list
* __Request headers:__
```
authorization: Bearer 4Uw/bFj7LZVI1dGWjz5T
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "page": 1,
  "page_size": 2
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAy2C2ZBjcDAAAAuI
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "rooms": [
    {
      "active_stream": null,
      "administrators": null,
      "chat_type": "dropchat",
      "color": "#FF006D",
      "created": "2022-10-30T10:10:23.650882Z",
      "id": 102,
      "is_access_required": null,
      "key": "TGtz6/uvNJ",
      "location": {
        "coordinates": [
          40.5,
          -50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "messages_count": 0,
      "moderators": null,
      "place": null,
      "private": false,
      "title": "Sapiente voluptatem!",
      "users": null
    },
    {
      "active_stream": null,
      "administrators": null,
      "chat_type": "dropchat",
      "color": "#FF006D",
      "created": "2022-01-01T00:00:00.000000Z",
      "id": 101,
      "is_access_required": null,
      "key": "itzcwfMQOm",
      "location": {
        "coordinates": [
          40.5,
          -50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "messages_count": 0,
      "moderators": null,
      "place": null,
      "private": false,
      "title": "Qui facere!",
      "users": null
    }
  ]
}
```

#### dropchat_list doesn't return private chats
##### Request
* __Method:__ POST
* __Path:__ /api/dropchat_list
* __Request headers:__
```
authorization: Bearer 71vdYltgGj863yOUKM/4
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "page": 2,
  "page_size": 2
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzA1LDjBbxwAABTM
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "rooms": []
}
```

#### dropchat_list returns error on invalid params
##### Request
* __Method:__ POST
* __Path:__ /api/dropchat_list
* __Request headers:__
```
authorization: Bearer FJC4u4C6Yfm4BuN3NcHj
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "page": "first"
}
```

##### Response
* __Status__: 422
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzTLs-jw-iEAABUB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "error": "invalid_param_type",
  "reason": "invalid_param_type",
  "success": false
}
```

## Web.FollowingController
### <a id=web-followingcontroller-index></a>index
#### index actions for followings
##### Request
* __Method:__ GET
* __Path:__ /api/following
* __Request headers:__
```
authorization: Bearer wJ5utwrMnso70aTpUf9+
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA4qSzygohgoAABLI
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "area": "Kuhn",
      "avatar": "http://robohash.org/set_set2/bgset_bg1/lSYMhnwGTD",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/lSYMhnwGTD",
      "bio": "Dolore fugiat aut sunt cum consequatur tempora unde voluptatibus ipsam.",
      "birthdate": "1925-07-25",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.852671Z",
      "email": "dandre.tillman@stamm.name",
      "enable_push_notifications": false,
      "first_name": "Lavina",
      "id": 1655,
      "is_follower": null,
      "is_following": null,
      "last_name": "Sawayn",
      "last_online_at": null,
      "phone": "551-799-9195",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "brionna.lang-47",
      "verified_phone": "551-799-9195"
    },
    {
      "area": "West Petra",
      "avatar": "http://robohash.org/set_set1/bgset_bg1/6MYAFJWfSOlHKJfone",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/6MYAFJWfSOlHKJfone",
      "bio": "Officia omnis non quia quia et nobis porro beatae perspiciatis!",
      "birthdate": "1965-10-07",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.855541Z",
      "email": "sven.mosciski@reichel.biz",
      "enable_push_notifications": false,
      "first_name": "Jacquelyn",
      "id": 1657,
      "is_follower": null,
      "is_following": null,
      "last_name": "Ankunding",
      "last_online_at": null,
      "phone": "3484528105",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "maximillia2062-32",
      "verified_phone": "3484528105"
    },
    {
      "area": "Manley",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/egTr",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/egTr",
      "bio": "Et consequatur vero assumenda excepturi aut perferendis doloremque minima quae.",
      "birthdate": "1968-05-31",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.857963Z",
      "email": "lia.waters@oreilly.net",
      "enable_push_notifications": false,
      "first_name": "Wyman",
      "id": 1659,
      "is_follower": null,
      "is_following": null,
      "last_name": "Yost",
      "last_online_at": null,
      "phone": "(342) 401-4172",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "maxime2020-95",
      "verified_phone": "(342) 401-4172"
    },
    {
      "area": "Velma",
      "avatar": "http://robohash.org/set_set3/bgset_bg2/kkQVEvFFZwuyD",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/kkQVEvFFZwuyD",
      "bio": "Sed accusamus perspiciatis illo omnis voluptates temporibus sit inventore sequi?",
      "birthdate": "1992-06-09",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.860124Z",
      "email": "adella2060@moen.info",
      "enable_push_notifications": false,
      "first_name": "Malika",
      "id": 1663,
      "is_follower": null,
      "is_following": null,
      "last_name": "Cummerata",
      "last_online_at": null,
      "phone": "(247) 752-7943",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "freeda.toy-80",
      "verified_phone": "(247) 752-7943"
    },
    {
      "area": "South Delaney",
      "avatar": "http://robohash.org/set_set3/bgset_bg1/y63jcdONTOf",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/y63jcdONTOf",
      "bio": "Sit ullam suscipit placeat dolorem dicta ut nemo molestias ut!",
      "birthdate": "1941-11-06",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.862754Z",
      "email": "alva_bins@murazik.biz",
      "enable_push_notifications": false,
      "first_name": "Rebekah",
      "id": 1665,
      "is_follower": null,
      "is_following": null,
      "last_name": "Wilkinson",
      "last_online_at": null,
      "phone": "437.415.7220",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "johnson.osinski-21",
      "verified_phone": "437.415.7220"
    },
    {
      "area": "East Fermin",
      "avatar": "http://robohash.org/set_set1/bgset_bg1/K3b2rC4gDgptaoih",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/K3b2rC4gDgptaoih",
      "bio": "Nulla sed ullam velit sunt praesentium quaerat et in qui.",
      "birthdate": "1963-02-03",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.864778Z",
      "email": "jevon1912@steuber.name",
      "enable_push_notifications": false,
      "first_name": "Concepcion",
      "id": 1668,
      "is_follower": null,
      "is_following": null,
      "last_name": "Tillman",
      "last_online_at": null,
      "phone": "(343) 381-6438",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "adella_kutch-64",
      "verified_phone": "(343) 381-6438"
    },
    {
      "area": "North Lucinda",
      "avatar": "http://robohash.org/set_set3/bgset_bg1/JzTtB8xAd",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/JzTtB8xAd",
      "bio": "Rerum occaecati neque incidunt voluptatibus consequatur iure et ipsam non.",
      "birthdate": "1982-01-06",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.866809Z",
      "email": "winston1960@crona.org",
      "enable_push_notifications": false,
      "first_name": "Jackie",
      "id": 1670,
      "is_follower": null,
      "is_following": null,
      "last_name": "Jerde",
      "last_online_at": null,
      "phone": "7012226051",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "anais_konopelski-8",
      "verified_phone": "7012226051"
    },
    {
      "area": "Port Winfield",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/WU2",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/WU2",
      "bio": "Dolor atque natus libero consequatur sed non ducimus natus assumenda.",
      "birthdate": "2002-07-26",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.868473Z",
      "email": "mae1946@okeefe.name",
      "enable_push_notifications": false,
      "first_name": "Heloise",
      "id": 1671,
      "is_follower": null,
      "is_following": null,
      "last_name": "Powlowski",
      "last_online_at": null,
      "phone": "(810) 653-9327",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "nola_skiles-62",
      "verified_phone": "(810) 653-9327"
    },
    {
      "area": "Dietrich",
      "avatar": "http://robohash.org/set_set3/bgset_bg1/SlOErpZ9OPMemt",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/SlOErpZ9OPMemt",
      "bio": "Rerum quia odio ab reprehenderit et non libero id hic.",
      "birthdate": "1958-11-28",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.870323Z",
      "email": "michaela2062@gibson.net",
      "enable_push_notifications": false,
      "first_name": "Donavon",
      "id": 1672,
      "is_follower": null,
      "is_following": null,
      "last_name": "Rolfson",
      "last_online_at": null,
      "phone": "2789820067",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "madeline2061-25",
      "verified_phone": "2789820067"
    },
    {
      "area": "New Noemi",
      "avatar": "http://robohash.org/set_set2/bgset_bg2/GYeRb9MmolwPLouz",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/GYeRb9MmolwPLouz",
      "bio": "Omnis sunt minus occaecati ipsum aperiam dolore sint fugiat eligendi.",
      "birthdate": "1980-04-08",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.872269Z",
      "email": "duane2076@robel.info",
      "enable_push_notifications": false,
      "first_name": "Lisa",
      "id": 1674,
      "is_follower": null,
      "is_following": null,
      "last_name": "Konopelski",
      "last_online_at": null,
      "phone": "361.269.4257",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "willis.ziemann-28",
      "verified_phone": "361.269.4257"
    }
  ],
  "next": "http://localhost:4001/api/following?page=2",
  "page_number": 1,
  "page_size": 10,
  "prev": null,
  "total_entries": 75,
  "total_pages": 8
}
```

### <a id=web-followingcontroller-index_followers></a>index_followers
#### index actions for followers
##### Request
* __Method:__ GET
* __Path:__ /api/followers
* __Request headers:__
```
authorization: Bearer KWRc3uJll4o4uvgjm17q
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA3MFzWBEdYQAAA8L
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "area": "Joannie",
      "avatar": "http://robohash.org/set_set3/bgset_bg2/jmiGyT4PQLELIu",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/jmiGyT4PQLELIu",
      "bio": "Qui aut quo eius beatae doloribus saepe est enim eum!",
      "birthdate": "1951-05-21",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.302708Z",
      "email": "trudie.mosciski@nienow.net",
      "enable_push_notifications": false,
      "first_name": "Samanta",
      "id": 1350,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Koch",
      "last_online_at": null,
      "phone": "955.486.1160",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "reynold.wilkinson-57",
      "verified_phone": "955.486.1160"
    },
    {
      "area": "Curtis",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/9UjipowXk",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/9UjipowXk",
      "bio": "Incidunt et officia laborum dolores rerum qui aut in molestias.",
      "birthdate": "1980-10-20",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.304940Z",
      "email": "marshall_swaniawski@nader.org",
      "enable_push_notifications": false,
      "first_name": "Magnolia",
      "id": 1352,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Buckridge",
      "last_online_at": null,
      "phone": "(869) 669-7219",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "michele1909-13",
      "verified_phone": "(869) 669-7219"
    },
    {
      "area": "North Shaun",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/3YLrmsaoEMFV",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/3YLrmsaoEMFV",
      "bio": "Velit non mollitia vel maxime accusantium fuga fugiat et et!",
      "birthdate": "1991-07-05",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.307928Z",
      "email": "bobby_bogan@wisoky.biz",
      "enable_push_notifications": false,
      "first_name": "Berenice",
      "id": 1353,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Boehm",
      "last_online_at": null,
      "phone": "370.837.1258",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "gladys_smith-36",
      "verified_phone": "370.837.1258"
    },
    {
      "area": "Rollin",
      "avatar": "http://robohash.org/set_set2/bgset_bg2/HlAoCoFelzLCaH",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/HlAoCoFelzLCaH",
      "bio": "Aut earum natus ipsam fuga et et ipsam id dolores!",
      "birthdate": "1932-06-10",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.310944Z",
      "email": "gennaro2053@barton.org",
      "enable_push_notifications": false,
      "first_name": "Savanah",
      "id": 1354,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Gleason",
      "last_online_at": null,
      "phone": "648-913-9712",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "chester2024-28",
      "verified_phone": "648-913-9712"
    },
    {
      "area": "Lake Davion",
      "avatar": "http://robohash.org/set_set2/bgset_bg1/kKKFeFwgoRjVBh",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/kKKFeFwgoRjVBh",
      "bio": "Nostrum molestias libero sit fugit aut amet voluptas libero corporis.",
      "birthdate": "2002-01-28",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.312823Z",
      "email": "kiana2096@murazik.org",
      "enable_push_notifications": false,
      "first_name": "Reed",
      "id": 1356,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Roberts",
      "last_online_at": null,
      "phone": "2043087606",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "jarret_keebler-58",
      "verified_phone": "2043087606"
    },
    {
      "area": "South Chester",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/Myf2qkV5td",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/Myf2qkV5td",
      "bio": "Tempore est rem temporibus veniam quod aspernatur voluptatem rerum modi.",
      "birthdate": "1936-04-09",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.314997Z",
      "email": "jared.aufderhar@kunde.com",
      "enable_push_notifications": false,
      "first_name": "Hardy",
      "id": 1358,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Hirthe",
      "last_online_at": null,
      "phone": "(577) 832-7704",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "monte.wyman-99",
      "verified_phone": "(577) 832-7704"
    },
    {
      "area": "New Hannah",
      "avatar": "http://robohash.org/set_set3/bgset_bg2/u750i3",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/u750i3",
      "bio": "Aliquam rerum sunt sit adipisci nihil vel eius dolore ullam.",
      "birthdate": "1978-02-22",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.317421Z",
      "email": "emery_koelpin@walker.org",
      "enable_push_notifications": false,
      "first_name": "Lulu",
      "id": 1361,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Johnston",
      "last_online_at": null,
      "phone": "718/392-5625",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "gabriel2093-86",
      "verified_phone": "718/392-5625"
    },
    {
      "area": "West Brain",
      "avatar": "http://robohash.org/set_set2/bgset_bg2/Z5Dwaq3JwBRsjO",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/Z5Dwaq3JwBRsjO",
      "bio": "Voluptatem expedita dolores quia iusto omnis et voluptate accusamus et?",
      "birthdate": "1981-02-28",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.319908Z",
      "email": "arely_batz@hauck.info",
      "enable_push_notifications": false,
      "first_name": "Aletha",
      "id": 1362,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Boyer",
      "last_online_at": null,
      "phone": "627/908-1440",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "santos2018-87",
      "verified_phone": "627/908-1440"
    },
    {
      "area": "Pearl",
      "avatar": "http://robohash.org/set_set1/bgset_bg2/wax0Vsyma6hS",
      "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/wax0Vsyma6hS",
      "bio": "Mollitia saepe esse vel amet quo rem nobis neque deserunt?",
      "birthdate": "1974-11-20",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.322663Z",
      "email": "assunta2067@osinski.name",
      "enable_push_notifications": false,
      "first_name": "Krystina",
      "id": 1365,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Franecki",
      "last_online_at": null,
      "phone": "(743) 572-3638",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "josephine2085-13",
      "verified_phone": "(743) 572-3638"
    },
    {
      "area": "North Adell",
      "avatar": "http://robohash.org/set_set3/bgset_bg1/fbrANPREuc5DehA",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/fbrANPREuc5DehA",
      "bio": "Est aut et ullam quam et omnis consequuntur placeat et!",
      "birthdate": "1967-09-04",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.325153Z",
      "email": "sasha_feeney@bartoletti.net",
      "enable_push_notifications": false,
      "first_name": "Brenna",
      "id": 1366,
      "is_followed": false,
      "is_follower": null,
      "is_following": null,
      "last_name": "Kessler",
      "last_online_at": null,
      "phone": "306/232-9400",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "moshe1990-24",
      "verified_phone": "306/232-9400"
    }
  ],
  "next": "http://localhost:4001/api/followers?page=2",
  "page_number": 1,
  "page_size": 10,
  "prev": null,
  "total_entries": 75,
  "total_pages": 8
}
```

### <a id=web-followingcontroller-user_followers></a>user_followers
#### user followers returns user followers
##### Request
* __Method:__ GET
* __Path:__ /api/user/1328/followers
* __Request headers:__
```
authorization: Bearer CXkmTXAFYN1BmS756UWu
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA1No7AgPbvQAABfC
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "area": "Lake Tyrell",
      "avatar": "http://robohash.org/set_set2/bgset_bg2/G07WetJ8hT",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/G07WetJ8hT",
      "bio": "Sed error delectus accusamus ut consequatur laudantium eaque nam fugiat.",
      "birthdate": "1963-08-16",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.282790Z",
      "email": "casimir_nitzsche@corkery.info",
      "enable_push_notifications": false,
      "first_name": "Edgardo",
      "id": 1329,
      "is_follower": null,
      "is_following": null,
      "last_name": "Bechtelar",
      "last_online_at": null,
      "phone": "866/865-7209",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "cassidy.smith-17",
      "verified_phone": "866/865-7209"
    },
    {
      "area": "Port Monserrat",
      "avatar": "http://robohash.org/set_set2/bgset_bg2/0LBkEI9IudHZ",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/0LBkEI9IudHZ",
      "bio": "Dolor dolor ut debitis qui ut adipisci et repellat et!",
      "birthdate": "1928-10-20",
      "country_code": "+1",
      "date_joined": "2022-10-30T10:10:24.283944Z",
      "email": "rodrick_wolf@fahey.com",
      "enable_push_notifications": false,
      "first_name": "Americo",
      "id": 1331,
      "is_follower": null,
      "is_following": null,
      "last_name": "Bosco",
      "last_online_at": null,
      "phone": "257.779.0939",
      "prefered_radius": 1,
      "sex": "M",
      "user_points": {
        "general": 0.0,
        "stream": 0.0
      },
      "user_real_location": null,
      "user_safe_location": null,
      "user_tags": [],
      "username": "diamond_lemke-70",
      "verified_phone": "257.779.0939"
    }
  ],
  "next": null,
  "page_number": 1,
  "page_size": 10,
  "prev": null,
  "total_entries": 2,
  "total_pages": 1
}
```

## Web.InterestController
### <a id=web-interestcontroller-index></a>index
#### index lists all interests
##### Request
* __Method:__ GET
* __Path:__ /api/interests
* __Request headers:__
```
authorization: Bearer 6lEsFAcJhEv9X7JTPtaJ
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzukpdBP5PQAAAzL
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "disabled?": false,
      "hashtag": "beer",
      "icon": "🍺",
      "id": 197,
      "inserted_at": "2022-10-30T10:10:24.000000Z",
      "popularity": 0
    },
    {
      "disabled?": false,
      "hashtag": "books",
      "icon": "📚",
      "id": 201,
      "inserted_at": "2022-10-30T10:10:24.000000Z",
      "popularity": 0
    },
    {
      "disabled?": false,
      "hashtag": "europe",
      "icon": "🇪🇺",
      "id": 199,
      "inserted_at": "2022-10-30T10:10:24.000000Z",
      "popularity": 0
    },
    {
      "disabled?": false,
      "hashtag": "fine-dining",
      "icon": "🍴",
      "id": 198,
      "inserted_at": "2022-10-30T10:10:24.000000Z",
      "popularity": 0
    },
    {
      "disabled?": false,
      "hashtag": "rome",
      "icon": "🍴",
      "id": 200,
      "inserted_at": "2022-10-30T10:10:24.000000Z",
      "popularity": 0
    }
  ],
  "next": null,
  "page_number": 1,
  "page_size": 10,
  "prev": null,
  "total_entries": 5,
  "total_pages": 1
}
```

### <a id=web-interestcontroller-categories></a>categories
#### categories lists all interest categories
##### Request
* __Method:__ GET
* __Path:__ /api/interests/categories
* __Request headers:__
```
authorization: Bearer Ack7qkcLb/XKBgIuTIwy
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRAzzePxC_YHIAABWB
x-version: f30c61431aa2
```
* __Response body:__
```json
[
  {
    "icon": "📚",
    "name": "alphabet"
  },
  {
    "icon": "🍴",
    "name": "food"
  },
  {
    "icon": "🏆",
    "name": "sports"
  },
  {
    "icon": "✈️",
    "name": "travel"
  }
]
```

## API /api/notifications
### <a id=api-api-notifications-index></a>index
#### with a notification of each type
##### Request
* __Method:__ GET
* __Path:__ /api/notifications?page_size=25
* __Request headers:__
```
authorization: Bearer uu30ukrywzAL7ftebL63
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA4olioCMKlQAABjE
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "description": "dayne_ullrich-67 started a dropchat stream about \"Omnis.\"",
      "dropchat_key": "/D7vpsgJFN",
      "id": 67,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.212670Z",
      "unread": true,
      "verb": "dropchats:streams:new:followed"
    },
    {
      "description": "Howdy! You are now in. Come join us on BillBored",
      "id": 66,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.206577Z",
      "unread": true,
      "verb": "access:granted"
    },
    {
      "description": "krystal2067-75 started a dropchat room about \"Title!\"",
      "dropchat_key": "sDOGAVkk2p",
      "id": 65,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.205406Z",
      "unread": true,
      "verb": "dropchats:new:followed"
    },
    {
      "description": "Hello!",
      "id": 64,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.200987Z",
      "unread": true,
      "verb": "area_notifications:scheduled"
    },
    {
      "description": "Est. is approaching. It starts in about 12 hours.",
      "event_id": "65",
      "id": 63,
      "level": "info",
      "post_id": "284",
      "timestamp": "2022-10-30T10:10:25.195405Z",
      "unread": true,
      "verb": "event:approaching"
    },
    {
      "attendant_id": "1966",
      "description": "chaz1931-40 is going to attend your event Vel!",
      "event_id": "64",
      "id": 62,
      "level": "info",
      "post_id": "283",
      "timestamp": "2022-10-30T10:10:25.190784Z",
      "unread": true,
      "verb": "event:attendant:new"
    },
    {
      "description": "julie_orn-57 voted on your poll Quia!",
      "id": 61,
      "level": "info",
      "poll_id": "11",
      "post_id": "282",
      "timestamp": "2022-10-30T10:10:25.182359Z",
      "unread": true,
      "verb": "poll_vote:new",
      "voter_id": "1963"
    },
    {
      "description": "ephraim_rowe-3 started following you",
      "follower_id": "1957",
      "follower_username": "ephraim_rowe-3",
      "following_id": "338",
      "id": 60,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.171052Z",
      "unread": true,
      "verb": "following:new"
    },
    {
      "description": "Quia! matches your interests",
      "event_id": "63",
      "id": 59,
      "level": "info",
      "post_id": "280",
      "timestamp": "2022-10-30T10:10:25.167341Z",
      "unread": true,
      "verb": "events:matching_interests"
    },
    {
      "description": "dakota_zemlak-8 replied to you: not sure",
      "id": 58,
      "level": "info",
      "reply_id": "62",
      "room_key": "ugps6UWs/k",
      "sender_id": "1950",
      "timestamp": "2022-10-30T10:10:25.162641Z",
      "unread": true,
      "verb": "chats:message:reply"
    },
    {
      "description": "cristobal2086-22 tagged you in Voluptates delectus?: @presley2087-95 what do you think?",
      "id": 57,
      "level": "info",
      "message_id": "60",
      "room_key": "Y4iDSysGQX",
      "tagger_id": "1945",
      "timestamp": "2022-10-30T10:10:25.157169Z",
      "unread": true,
      "verb": "chats:message:tagged"
    },
    {
      "description": "vernice2089-55 requested write access in dropchat Repudiandae sed.",
      "dropchat_key": "uKcolF8bwt",
      "id": 56,
      "level": "info",
      "request_id": "5",
      "requester_id": "1940",
      "timestamp": "2022-10-30T10:10:25.152991Z",
      "unread": true,
      "verb": "chats:privilege:request"
    },
    {
      "description": "you've been given write access in dropchat Non aliquam.",
      "dropchat_key": "5+zImHiiMK",
      "id": 55,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.147980Z",
      "unread": true,
      "verb": "chats:privilege:granted"
    },
    {
      "description": "gerson2008-45 rejected your post",
      "id": 54,
      "level": "info",
      "post_id": "279",
      "rejector_id": "1933",
      "timestamp": "2022-10-30T10:10:25.144380Z",
      "unread": true,
      "verb": "posts:approve:request:reject"
    },
    {
      "description": "rose2033-93 requested your approval for a post",
      "id": 53,
      "level": "info",
      "post_id": "278",
      "requester_id": "1927",
      "timestamp": "2022-10-30T10:10:25.137101Z",
      "unread": true,
      "verb": "posts:approve:request"
    },
    {
      "author_id": "1924",
      "comment_id": "261",
      "description": "kavon.mccullough-97 commented on your post",
      "id": 52,
      "level": "info",
      "post_id": "277",
      "timestamp": "2022-10-30T10:10:25.131631Z",
      "unread": true,
      "verb": "posts:comment"
    },
    {
      "comment_id": "257",
      "description": "lenny1994-55 does not like your comment",
      "downvoter_id": "1921",
      "id": 51,
      "level": "info",
      "post_id": "276",
      "timestamp": "2022-10-30T10:10:25.127170Z",
      "unread": true,
      "verb": "post:comments:reacted"
    },
    {
      "comment_id": "251",
      "description": "esperanza1985-75 liked your comment",
      "id": 50,
      "level": "info",
      "post_id": "274",
      "timestamp": "2022-10-30T10:10:25.118168Z",
      "unread": true,
      "upvoter_id": "1915",
      "verb": "post:comments:like"
    },
    {
      "description": "lottie1962-92 does not like your post Magnam!",
      "downvote_id": "86",
      "downvoter_id": "1908",
      "id": 48,
      "level": "info",
      "post_id": "273",
      "timestamp": "2022-10-30T10:10:25.109714Z",
      "unread": true,
      "verb": "posts:reacted"
    },
    {
      "description": "corrine2050-6 liked your post Occaecati.",
      "id": 47,
      "level": "info",
      "post_id": "272",
      "timestamp": "2022-10-30T10:10:25.101228Z",
      "unread": true,
      "upvote_id": "67",
      "upvoter_id": "1903",
      "verb": "posts:like"
    },
    {
      "description": "New popular dropchat around you: Omnis perspiciatis!",
      "dropchat_key": "uiDxMiJaio",
      "id": 45,
      "level": "info",
      "timestamp": "2022-10-30T10:10:25.094818Z",
      "unread": true,
      "verb": "dropchats:new:popular"
    },
    {
      "description": "New popular post around you: Blanditiis!",
      "id": 44,
      "level": "info",
      "post_id": "271",
      "timestamp": "2022-10-30T10:10:25.092587Z",
      "unread": true,
      "verb": "posts:new:popular"
    }
  ],
  "next": null,
  "page_number": 1,
  "page_size": 25,
  "prev": null,
  "total_entries": 22,
  "total_pages": 1
}
```

## Web.PostController
### <a id=web-postcontroller-show></a>show
#### event post tracks view
##### Request
* __Method:__ GET
* __Path:__ /api/post/713
* __Request headers:__
```
authorization: Bearer 7l3CjfxtWKfk42O6Ynq2
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "city": "New York",
  "country": "USA",
  "lat": "40.730610",
  "lon": "-73.935242"
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBIs_YbDEO8QAACuC
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "approved?": true,
  "author": {
    "avatar": "http://robohash.org/set_set2/bgset_bg2/qlbu",
    "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/qlbu",
    "first_name": "Dexter",
    "id": 3327,
    "last_name": "Schroeder",
    "username": "antone2065-57"
  },
  "body": "Quae enim amet voluptas et ex assumenda illo culpa nam.",
  "business": null,
  "business_admin": null,
  "business_name": null,
  "comments_count": 0,
  "downvotes_count": 0,
  "event_provider": "",
  "events": [],
  "fake_location?": false,
  "id": 713,
  "inserted_at": "2022-10-30T10:10:30.000000Z",
  "interests": [],
  "location": {
    "coordinates": [
      50.0,
      50.0
    ],
    "crs": {
      "properties": {
        "name": "EPSG:4326"
      },
      "type": "name"
    },
    "type": "Point"
  },
  "media_file_keys": [],
  "place": null,
  "polls": [],
  "post_cost": null,
  "private?": false,
  "title": "Ut.",
  "type": "regular",
  "universal_link": "http://localhost:4001/posts/NzEz",
  "updated_at": "2022-10-30T10:10:30.000000Z",
  "upvotes_count": 0,
  "user_downvoted?": false,
  "user_upvoted?": false
}
```

### <a id=web-postcontroller-create></a>create
#### create business offer when user is owner
##### Request
* __Method:__ POST
* __Path:__ /api/posts
* __Request headers:__
```
authorization: Bearer u/zX5JA4QaKUmP0dOsxI
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "body": "Description",
  "business_offer": {
    "bar_code": "1234098765",
    "business_address": "Broken Dreams blvd. 1",
    "discount": "20%",
    "discount_code": "SALE0001",
    "expires_at": "2038-01-01 01:01:01Z",
    "qr_code": "SALE0001"
  },
  "business_username": "sydnee.yundt-41",
  "interests": [
    "#hash",
    {
      "hashtag": "#hashtag"
    }
  ],
  "location": {
    "coordinates": [
      30.7008,
      76.7885
    ],
    "type": "Point"
  },
  "media_file_keys": [
    "4d7a087b-058a-4850-a9f7-1e958e64b8f4"
  ],
  "title": "Business offer",
  "type": "offer"
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBKJIpOizzMUAACBB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "result": {
    "approved?": true,
    "author": {
      "avatar": "http://robohash.org/set_set3/bgset_bg2/f",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/f",
      "first_name": "Clovis",
      "id": 3376,
      "last_name": "Ward",
      "username": "sydnee.yundt-41"
    },
    "body": "Description",
    "business": {
      "avatar": "http://robohash.org/set_set3/bgset_bg2/f",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/f",
      "first_name": "Clovis",
      "id": 3376,
      "last_name": "Ward",
      "username": "sydnee.yundt-41"
    },
    "business_admin": {
      "avatar": "http://robohash.org/set_set3/bgset_bg2/f",
      "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/f",
      "first_name": "Clovis",
      "id": 3376,
      "last_name": "Ward",
      "username": "sydnee.yundt-41"
    },
    "business_name": "sydnee.yundt-41",
    "business_offer": {
      "bar_code": "1234098765",
      "business_address": "Broken Dreams blvd. 1",
      "discount": "20%",
      "discount_code": "SALE0001",
      "expires_at": "2038-01-01T01:01:01.000000Z",
      "qr_code": "SALE0001"
    },
    "comments_count": 0,
    "downvotes_count": 0,
    "event_provider": "",
    "events": [],
    "fake_location?": false,
    "id": 740,
    "inserted_at": "2022-10-30T10:10:29.918727Z",
    "interests": [
      "hash",
      "hashtag"
    ],
    "location": {
      "coordinates": [
        30.7008,
        76.7885
      ],
      "crs": {
        "properties": {
          "name": "EPSG:4326"
        },
        "type": "name"
      },
      "type": "Point"
    },
    "media_file_keys": [
      {
        "results": [
          {
            "media": null,
            "media_key": "4d7a087b-058a-4850-a9f7-1e958e64b8f4",
            "media_thumbnail": null,
            "media_type": "other",
            "owner": {}
          }
        ]
      }
    ],
    "place": null,
    "polls": [],
    "post_cost": null,
    "private?": false,
    "title": "Business offer",
    "type": "offer",
    "universal_link": "http://localhost:4001/posts/NzQw",
    "updated_at": "2022-10-30T10:10:29.918727Z",
    "upvotes_count": 0,
    "user_downvoted?": false,
    "user_upvoted?": false
  },
  "success": true
}
```

#### create business offer when user is admin
##### Request
* __Method:__ POST
* __Path:__ /api/posts
* __Request headers:__
```
authorization: Bearer l4kv5y72z8tqVofpkIiV
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "body": "Description",
  "business_offer": {
    "bar_code": "1234098765",
    "business_address": "Broken Dreams blvd. 1",
    "discount": "20%",
    "discount_code": "SALE0001",
    "expires_at": "2038-01-01 01:01:01Z",
    "qr_code": "SALE0001"
  },
  "business_username": "jorge_rempel-25",
  "interests": [
    "#hash",
    {
      "hashtag": "#hashtag"
    }
  ],
  "location": {
    "coordinates": [
      30.7008,
      76.7885
    ],
    "type": "Point"
  },
  "media_file_keys": [
    "e4a27d7f-3d5c-4ef8-a15f-a48e97da7671"
  ],
  "title": "Business offer",
  "type": "offer"
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBI6B8iD8O_AAAB9H
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "result": {
    "approved?": false,
    "author": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "first_name": "Katelynn",
      "id": 3340,
      "last_name": "Mann",
      "username": "jorge_rempel-25"
    },
    "body": "Description",
    "business": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "first_name": "Katelynn",
      "id": 3340,
      "last_name": "Mann",
      "username": "jorge_rempel-25"
    },
    "business_admin": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/8PwphFEPV3PdPdK0U",
      "first_name": "Katelynn",
      "id": 3340,
      "last_name": "Mann",
      "username": "jorge_rempel-25"
    },
    "business_name": "jorge_rempel-25",
    "business_offer": {
      "bar_code": "1234098765",
      "business_address": "Broken Dreams blvd. 1",
      "discount": "20%",
      "discount_code": "SALE0001",
      "expires_at": "2038-01-01T01:01:01.000000Z",
      "qr_code": "SALE0001"
    },
    "comments_count": 0,
    "downvotes_count": 0,
    "event_provider": "",
    "events": [],
    "fake_location?": false,
    "id": 723,
    "inserted_at": "2022-10-30T10:10:29.589232Z",
    "interests": [
      "hash",
      "hashtag"
    ],
    "location": {
      "coordinates": [
        30.7008,
        76.7885
      ],
      "crs": {
        "properties": {
          "name": "EPSG:4326"
        },
        "type": "name"
      },
      "type": "Point"
    },
    "media_file_keys": [
      {
        "results": [
          {
            "media": null,
            "media_key": "e4a27d7f-3d5c-4ef8-a15f-a48e97da7671",
            "media_thumbnail": null,
            "media_type": "other",
            "owner": {}
          }
        ]
      }
    ],
    "place": null,
    "polls": [],
    "post_cost": null,
    "private?": false,
    "title": "Business offer",
    "type": "offer",
    "universal_link": "http://localhost:4001/posts/NzIz",
    "updated_at": "2022-10-30T10:10:29.589232Z",
    "upvotes_count": 0,
    "user_downvoted?": false,
    "user_upvoted?": false
  },
  "success": true
}
```

### <a id=web-postcontroller-delete></a>delete
#### delete business offer succeeds by a business owner
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/693
* __Request headers:__
```
authorization: Bearer ZJiTLcexSm0MiO9jqXtx
```

##### Response
* __Status__: 204
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBIOWSqAhrE0AABdI
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete business offer succeeds by a business admin
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/724
* __Request headers:__
```
authorization: Bearer AmTxoYmloppUmV8/bS9C
```

##### Response
* __Status__: 204
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBI_l14CirvEAACJE
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete business offer succeeds by a business member who is the post's author
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/848
* __Request headers:__
```
authorization: Bearer Zo3aN/bEXAU8JAI7ma5l
```

##### Response
* __Status__: 204
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBNPs-PCkKAQAACCD
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete business offer fails by a business member who is not the post's author
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/739
* __Request headers:__
```
authorization: Bearer KhZNJ+veTd2RwptRS6Bw
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBKGozvCmacIAACMF
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete business offer fails by the post's author who is not a member
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/794
* __Request headers:__
```
authorization: Bearer lHRqhdX7QWetMn21Se2z
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBLfrLDAtV4AAABqK
x-version: f30c61431aa2
```
* __Response body:__
```json

```

#### delete business offer fails by another user
##### Request
* __Method:__ DELETE
* __Path:__ /api/post/778
* __Request headers:__
```
authorization: Bearer 7Jf1r2ehlwzs9TwI1Snh
```

##### Response
* __Status__: 403
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBLLYsgjzm3wAAC4C
x-version: f30c61431aa2
```
* __Response body:__
```json

```

### <a id=web-postcontroller-update></a>update
#### update business offer succeeds when user is owner
##### Request
* __Method:__ PUT
* __Path:__ /api/post/730
* __Request headers:__
```
authorization: Bearer 0FtzdIse0OddrCmCOnJL
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "business_offer": {
    "bar_code": "1234098765",
    "business_address": "Broken Dreams blvd. 123",
    "discount": "80%",
    "discount_code": "SALE4321",
    "expires_at": "2028-01-01 01:01:01Z",
    "qr_code": "CODE4321"
  }
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBJMD-7go4voAABkG
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "result": {
    "approved?": true,
    "author": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "first_name": "Dorcas",
      "id": 3352,
      "last_name": "Grady",
      "username": "business-burley.ortiz-7"
    },
    "body": "Qui minima enim dolores.",
    "business": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "first_name": "Dorcas",
      "id": 3352,
      "last_name": "Grady",
      "username": "business-burley.ortiz-7"
    },
    "business_admin": {
      "avatar": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/z2EvZXfYmdS",
      "first_name": "Dorcas",
      "id": 3352,
      "last_name": "Grady",
      "username": "business-burley.ortiz-7"
    },
    "business_name": "Dorcas",
    "business_offer": {
      "bar_code": "1234098765",
      "business_address": "Broken Dreams blvd. 123",
      "discount": "80%",
      "discount_code": "SALE4321",
      "expires_at": "2028-01-01T01:01:01.000000Z",
      "qr_code": "CODE4321"
    },
    "comments_count": 0,
    "downvotes_count": 0,
    "event_provider": "",
    "events": [],
    "fake_location?": false,
    "id": 730,
    "inserted_at": "2022-10-30T10:10:30.000000Z",
    "interests": [],
    "location": {
      "coordinates": [
        50.0,
        50.0
      ],
      "crs": {
        "properties": {
          "name": "EPSG:4326"
        },
        "type": "name"
      },
      "type": "Point"
    },
    "media_file_keys": [],
    "place": null,
    "polls": [],
    "post_cost": null,
    "private?": false,
    "title": "sed",
    "type": "offer",
    "universal_link": "http://localhost:4001/posts/NzMw",
    "updated_at": "2022-10-30T10:10:30.000000Z",
    "upvotes_count": 0,
    "user_downvoted?": false,
    "user_upvoted?": false
  },
  "success": true
}
```

### <a id=web-postcontroller-show></a>show
#### show business offer returns complete post
##### Request
* __Method:__ GET
* __Path:__ /api/post/687
* __Request headers:__
```
authorization: Bearer u4KjQnyfIfTvXGQEt6TN
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "business_offer": {
    "bar_code": "1234098765",
    "business_address": "Broken Dreams blvd. 123",
    "discount": "80%",
    "discount_code": "SALE4321",
    "expires_at": "2028-01-01 01:01:01Z",
    "qr_code": "CODE4321"
  }
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBIKgZWiAQ3oAACCF
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "approved?": true,
  "author": {
    "avatar": "http://robohash.org/set_set1/bgset_bg2/l7OijMYHJv",
    "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/l7OijMYHJv",
    "first_name": "Delfina",
    "id": 3290,
    "last_name": "Schiller",
    "username": "jarrell.blick-36"
  },
  "body": "Molestiae ut hic et sequi eum et omnis iste?",
  "business": {
    "avatar": "http://robohash.org/set_set1/bgset_bg1/4N1ag",
    "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/4N1ag",
    "first_name": "Garland",
    "id": 3289,
    "last_name": "D'Amore",
    "username": "business-elissa2098-49"
  },
  "business_admin": {
    "avatar": "http://robohash.org/set_set1/bgset_bg1/4N1ag",
    "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/4N1ag",
    "first_name": "Garland",
    "id": 3289,
    "last_name": "D'Amore",
    "username": "business-elissa2098-49"
  },
  "business_name": "Garland",
  "business_offer": {
    "bar_code": "4321",
    "business_address": null,
    "discount": "25%",
    "discount_code": "SALE0001",
    "expires_at": "2038-01-01T01:01:01.000000Z",
    "qr_code": "CODE0001"
  },
  "comments_count": 0,
  "downvotes_count": 0,
  "event_provider": "",
  "events": [],
  "fake_location?": false,
  "id": 687,
  "inserted_at": "2022-10-30T10:10:29.000000Z",
  "interests": [],
  "location": {
    "coordinates": [
      50.0,
      50.0
    ],
    "crs": {
      "properties": {
        "name": "EPSG:4326"
      },
      "type": "name"
    },
    "type": "Point"
  },
  "media_file_keys": [],
  "place": null,
  "polls": [],
  "post_cost": null,
  "private?": false,
  "title": "culpa",
  "type": "offer",
  "universal_link": "http://localhost:4001/posts/Njg3",
  "updated_at": "2022-10-30T10:10:29.000000Z",
  "upvotes_count": 0,
  "user_downvoted?": false,
  "user_upvoted?": false
}
```

### <a id=web-postcontroller-list_nearby></a>list_nearby
#### list_nearby returns posts with geohashes touching radius
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer 0I8OKdRKYT0/dCF6OVlh
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "location": {
    "coordinates": [
      51.152344,
      -0.29315
    ],
    "type": "Point"
  },
  "precision": 4,
  "radius": 1300
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBKk5-QDlNsMAACEB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/i",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/i",
        "first_name": "Lew",
        "id": 3412,
        "last_name": "Hagenes",
        "username": "velva2059-16"
      },
      "body": "Minus necessitatibus laboriosam assumenda eveniet ex quam molestias harum aut?",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T11:10:30.002355Z",
          "doubts_count": 0,
          "id": 162,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Nobis?",
          "universal_link": "http://localhost:4001/events/MTYy",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 755,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.188059,
          -0.139366
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Et?",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/NzU1",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set2/bgset_bg2/gOH1o7rm",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg2/gOH1o7rm",
        "first_name": "Paxton",
        "id": 3411,
        "last_name": "Breitenberg",
        "username": "khalil2078-9"
      },
      "body": "Placeat ab quas tempora odio optio provident ab ad sit.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T05:10:30.002355Z",
          "doubts_count": 0,
          "id": 161,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Facere?",
          "universal_link": "http://localhost:4001/events/MTYx",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 754,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Accusamus.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/NzU0",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/SbD6M7lkwPC08Bm",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/SbD6M7lkwPC08Bm",
        "first_name": "Fritz",
        "id": 3414,
        "last_name": "Bradtke",
        "username": "orrin1912-85"
      },
      "body": "Sapiente perspiciatis nihil repudiandae facere rerum a cum error voluptas.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 757,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.110635,
          -0.147783
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Nesciunt!",
      "type": "vote",
      "universal_link": "http://localhost:4001/posts/NzU3",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/6ubtppA5kj5O",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/6ubtppA5kj5O",
        "first_name": "Keaton",
        "id": 3410,
        "last_name": "Walter",
        "username": "hubert.koss-92"
      },
      "body": "Vitae quo occaecati officiis atque eveniet ex sint nemo recusandae?",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 753,
      "inserted_at": "2022-10-30T10:09:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.23399,
          -0.138531
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Qui.",
      "type": "regular",
      "universal_link": "http://localhost:4001/posts/NzUz",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg2/PIURrCco4rNtqG",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/PIURrCco4rNtqG",
        "first_name": "Dayna",
        "id": 3413,
        "last_name": "Flatley",
        "username": "luciano1987-12"
      },
      "body": "Molestias sint aut porro dolorum cumque eius sunt sit ut!",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 756,
      "inserted_at": "2022-10-30T10:05:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.117661,
          -0.161299
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Ad.",
      "type": "regular",
      "universal_link": "http://localhost:4001/posts/NzU2",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby allows pagination
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer HCr8w7E281wWCVnUMENb
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "page": 1,
  "page_size": 1,
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBMtcxdDvCN0AACWE
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/FPTSwwEv4aYah",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/FPTSwwEv4aYah",
        "first_name": "Petra",
        "id": 3533,
        "last_name": "Goyette",
        "username": "jimmy.legros-84"
      },
      "body": "Nisi fuga maxime aperiam eveniet omnis dolor ut nihil in.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T11:10:30.585066Z",
          "doubts_count": 0,
          "id": 177,
          "inserted_at": "2022-10-30T10:10:31.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Alias.",
          "universal_link": "http://localhost:4001/events/MTc3",
          "updated_at": "2022-10-30T10:10:31.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 823,
      "inserted_at": "2022-10-30T10:10:31.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.188059,
          -0.139366
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Ex!",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/ODIz",
      "updated_at": "2022-10-30T10:10:31.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 1
}
```

#### list_nearby allows filtering by types
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer RzZHMbf3h9e7PiJGbdvb
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "location": {
    "coordinates": [
      51.152344,
      -0.29315
    ],
    "type": "Point"
  },
  "precision": 4,
  "radius": 1300,
  "types": [
    "vote",
    "event"
  ]
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBLb0lzDzkYkAAB7D
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/YPgP8yB7W",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/YPgP8yB7W",
        "first_name": "Sheridan",
        "id": 3481,
        "last_name": "Rolfson",
        "username": "anibal.mertz-76"
      },
      "body": "Esse inventore et et cumque aut fugit voluptas odit eaque.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T11:10:30.245913Z",
          "doubts_count": 0,
          "id": 169,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Eos.",
          "universal_link": "http://localhost:4001/events/MTY5",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 790,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.188059,
          -0.139366
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Voluptatem?",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/Nzkw",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/eTl",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/eTl",
        "first_name": "Isaias",
        "id": 3480,
        "last_name": "Jerde",
        "username": "joel1988-25"
      },
      "body": "Voluptatem et eveniet in dolor atque eum soluta magnam non.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T05:10:30.245913Z",
          "doubts_count": 0,
          "id": 168,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Numquam?",
          "universal_link": "http://localhost:4001/events/MTY4",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 789,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Nihil.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/Nzg5",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/OOhiO",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/OOhiO",
        "first_name": "Horacio",
        "id": 3483,
        "last_name": "Smitham",
        "username": "gennaro_rolfson-97"
      },
      "body": "Atque earum quas et quod natus voluptatem numquam repudiandae quos?",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 792,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.110635,
          -0.147783
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Nobis.",
      "type": "vote",
      "universal_link": "http://localhost:4001/posts/Nzky",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters posts by keyword
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer n7Wmvu1hyXtslpaCpelQ
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "keyword": "test"
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBNbgNMjYqBYAACRB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg2/xc8g3",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/xc8g3",
        "first_name": "Keaton",
        "id": 3597,
        "last_name": "Witting",
        "username": "thomas1982-99"
      },
      "body": "Nulla non saepe sint minus quod est ea dolor quia.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T10:10:30.793575Z",
          "doubts_count": 0,
          "id": 185,
          "inserted_at": "2022-10-30T10:10:31.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Automated testing",
          "universal_link": "http://localhost:4001/events/MTg1",
          "updated_at": "2022-10-30T10:10:31.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 860,
      "inserted_at": "2022-10-30T10:10:31.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Et?",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/ODYw",
      "updated_at": "2022-10-30T10:10:31.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters free events
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer Xd3gXujKVzqGrw6v7ncV
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "show_free": true
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBMciRLjxLH0AACNB
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg1/pppV6KIhr",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/pppV6KIhr",
        "first_name": "Viola",
        "id": 3519,
        "last_name": "Bosco",
        "username": "rubye_wisoky-48"
      },
      "body": "Delectus nesciunt ut autem adipisci laboriosam illo saepe vitae odit.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T10:10:30.529254Z",
          "doubts_count": 0,
          "id": 175,
          "inserted_at": "2022-10-30T10:10:31.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": 0.0,
          "refused_count": 0,
          "title": "Vel.",
          "universal_link": "http://localhost:4001/events/MTc1",
          "updated_at": "2022-10-30T10:10:31.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 814,
      "inserted_at": "2022-10-30T10:10:31.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Sit.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/ODE0",
      "updated_at": "2022-10-30T10:10:31.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters paid events
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer 2YgsSPU2/jIfBXt9nGlG
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "show_paid": true
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBKCNLZAl8-kAABmK
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/Fv",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/Fv",
        "first_name": "Hector",
        "id": 3370,
        "last_name": "Gleichner",
        "username": "vance_kilback-54"
      },
      "body": "Quia aut voluptas dolorem laudantium sed enim et omnis ab.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "GBP",
          "date": "2022-10-30T10:10:29.882216Z",
          "doubts_count": 0,
          "id": 157,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": 25.0,
          "refused_count": 0,
          "title": "Id.",
          "universal_link": "http://localhost:4001/events/MTU3",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 738,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Deserunt?",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/NzM4",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters courses
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer F1WhGpwiuwVRvwtzlNYR
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "show_courses": true,
    "show_paid": true
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBK6SQkBakFIAACUE
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/0HBdG2dfNqjid3PzmK",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/0HBdG2dfNqjid3PzmK",
        "first_name": "Jamie",
        "id": 3443,
        "last_name": "Balistreri",
        "username": "jaqueline_koch-83"
      },
      "body": "Aut minima quis necessitatibus esse saepe fuga autem ipsum aspernatur.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T10:10:30.116464Z",
          "doubts_count": 0,
          "id": 165,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": 500.0,
          "refused_count": 0,
          "title": "Learn DevOps in 21 hours",
          "universal_link": "http://localhost:4001/events/MTY1",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 771,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Sed.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/Nzcx",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters posts by event categories
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer F4rjxnE/JdHacrl5vrOf
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "categories": [
      "jogging"
    ]
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBIakXZBjttYAABtD
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/zKH136ke6Hu",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/zKH136ke6Hu",
        "first_name": "Zion",
        "id": 3306,
        "last_name": "Bradtke",
        "username": "carlotta.casper-36"
      },
      "body": "Nihil accusantium aut saepe rem cupiditate occaecati maxime iusto quod.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [
            "jogging"
          ],
          "child_friendly": false,
          "currency": "USD",
          "date": "2022-10-30T10:10:29.447610Z",
          "doubts_count": 0,
          "id": 149,
          "inserted_at": "2022-10-30T10:10:29.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Sed.",
          "universal_link": "http://localhost:4001/events/MTQ5",
          "updated_at": "2022-10-30T10:10:29.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 702,
      "inserted_at": "2022-10-30T10:10:29.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Ut.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/NzAy",
      "updated_at": "2022-10-30T10:10:29.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_nearby filters child friendly events
##### Request
* __Method:__ POST
* __Path:__ /api/posts/nearby
* __Request headers:__
```
authorization: Bearer MuwOrHm8Ap5xVijRvYG6
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "filter": {
    "show_child_friendly": true
  },
  "location": {
    "coordinates": [
      51.196289,
      -0.131836
    ],
    "type": "Point"
  },
  "precision": 5,
  "radius": 800
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBLlDdOjRAHcAAB8D
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg2/uHE7Yiwc",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/uHE7Yiwc",
        "first_name": "Brody",
        "id": 3494,
        "last_name": "Roberts",
        "username": "jayson1941-9"
      },
      "body": "Non a ducimus id sed qui ut harum enim maiores.",
      "business": null,
      "business_admin": null,
      "business_name": null,
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [
        {
          "accepted_count": 0,
          "attendees": [],
          "buy_ticket_link": null,
          "categories": [],
          "child_friendly": true,
          "currency": "USD",
          "date": "2022-10-30T10:10:30.296975Z",
          "doubts_count": 0,
          "id": 172,
          "inserted_at": "2022-10-30T10:10:30.000000Z",
          "invited_count": 0,
          "location": {
            "coordinates": [
              50.0,
              50.0
            ],
            "crs": {
              "properties": {
                "name": "EPSG:4326"
              },
              "type": "name"
            },
            "type": "Point"
          },
          "media_file_keys": [],
          "missed_count": 0,
          "other_date": null,
          "place": null,
          "presented_count": 0,
          "price": null,
          "refused_count": 0,
          "title": "Velit.",
          "universal_link": "http://localhost:4001/events/MTcy",
          "updated_at": "2022-10-30T10:10:30.000000Z",
          "user_attending?": false,
          "user_status": null
        }
      ],
      "fake_location?": false,
      "id": 801,
      "inserted_at": "2022-10-30T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          51.172073,
          -0.164037
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "Ullam.",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/ODAx",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

### <a id=web-postcontroller-list_business_posts></a>list_business_posts
#### list_business_posts returns approved posts in correct order
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/3496/posts
* __Request headers:__
```
authorization: Bearer K/F71ri5+yoIl0x5Gv8b
content-type: multipart/mixed; boundary=plug_conn_test
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBLrRxahjz_EAACPF
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg2/R2Ps",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/R2Ps",
        "first_name": "Hortense",
        "id": 3499,
        "last_name": "Hammes",
        "username": "dolores_kulas-89"
      },
      "body": "Aut sit voluptate fuga?",
      "business": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_admin": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_name": "Corbin",
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 804,
      "inserted_at": "2022-10-30T10:09:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "ducimus",
      "type": "poll",
      "universal_link": "http://localhost:4001/posts/ODA0",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/v8ucPh3c",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/v8ucPh3c",
        "first_name": "Adrienne",
        "id": 3498,
        "last_name": "Lowe",
        "username": "eloy_becker-75"
      },
      "body": "Dolor omnis distinctio consequatur?",
      "business": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_admin": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_name": "Corbin",
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 803,
      "inserted_at": "2022-10-30T09:55:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "voluptatem",
      "type": "event",
      "universal_link": "http://localhost:4001/posts/ODAz",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    },
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg2/14lqFPZKsD3sBsc9uo",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg2/14lqFPZKsD3sBsc9uo",
        "first_name": "Krista",
        "id": 3497,
        "last_name": "Wolf",
        "username": "angelica1919-77"
      },
      "body": "Hic porro quia id?",
      "business": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_admin": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/wvz",
        "first_name": "Corbin",
        "id": 3496,
        "last_name": "Stroman",
        "username": "business-ubaldo_sipes-45"
      },
      "business_name": "Corbin",
      "business_offer": {
        "bar_code": null,
        "business_address": null,
        "discount": null,
        "discount_code": null,
        "expires_at": "2022-10-31T10:10:30.315797Z",
        "qr_code": null
      },
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 802,
      "inserted_at": "2022-10-29T10:10:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "perspiciatis",
      "type": "offer",
      "universal_link": "http://localhost:4001/posts/ODAy",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

#### list_business_posts allows pagination
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/3344/posts
* __Request headers:__
```
authorization: Bearer lsVz6QV/MOXC7KiwlUFT
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "page": 1,
  "page_size": 1
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBJG4twgdIXsAABxD
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set3/bgset_bg1/q6GYcc1gP9pyC",
        "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/q6GYcc1gP9pyC",
        "first_name": "Enrique",
        "id": 3347,
        "last_name": "Jacobi",
        "username": "toby.cummings-2"
      },
      "body": "Voluptas beatae voluptatem quas debitis veniam beatae enim ullam.",
      "business": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/V6AHXDVHQV0KOl",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/V6AHXDVHQV0KOl",
        "first_name": "Pinkie",
        "id": 3344,
        "last_name": "O'Hara",
        "username": "business-garrison2088-89"
      },
      "business_admin": {
        "avatar": "http://robohash.org/set_set2/bgset_bg1/V6AHXDVHQV0KOl",
        "avatar_thumbnail": "http://robohash.org/set_set2/bgset_bg1/V6AHXDVHQV0KOl",
        "first_name": "Pinkie",
        "id": 3344,
        "last_name": "O'Hara",
        "username": "business-garrison2088-89"
      },
      "business_name": "Pinkie",
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 727,
      "inserted_at": "2022-10-30T10:09:30.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "voluptatem",
      "type": "poll",
      "universal_link": "http://localhost:4001/posts/NzI3",
      "updated_at": "2022-10-30T10:10:30.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 1
}
```

#### list_business_posts allows filtering by types
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/3524/posts
* __Request headers:__
```
authorization: Bearer pc8A76YqdZaTuvXnYjsO
content-type: multipart/mixed; boundary=plug_conn_test
```
* __Request body:__
```json
{
  "types": [
    "offer"
  ]
}
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBMntDRjpep8AAC6C
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "entries": [
    {
      "approved?": true,
      "author": {
        "avatar": "http://robohash.org/set_set1/bgset_bg2/8Mjlvr5NBniB",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg2/8Mjlvr5NBniB",
        "first_name": "Cleve",
        "id": 3525,
        "last_name": "Huel",
        "username": "harmon_gottlieb-17"
      },
      "body": "Molestiae vero exercitationem tenetur corporis est minus dolorem.",
      "business": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/i8G0gFOZfZ6jZ8eq65",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/i8G0gFOZfZ6jZ8eq65",
        "first_name": "Rosina",
        "id": 3524,
        "last_name": "Willms",
        "username": "business-oscar1918-81"
      },
      "business_admin": {
        "avatar": "http://robohash.org/set_set1/bgset_bg1/i8G0gFOZfZ6jZ8eq65",
        "avatar_thumbnail": "http://robohash.org/set_set1/bgset_bg1/i8G0gFOZfZ6jZ8eq65",
        "first_name": "Rosina",
        "id": 3524,
        "last_name": "Willms",
        "username": "business-oscar1918-81"
      },
      "business_name": "Rosina",
      "business_offer": {
        "bar_code": null,
        "business_address": null,
        "discount": null,
        "discount_code": null,
        "expires_at": "2022-10-31T10:10:30.566179Z",
        "qr_code": null
      },
      "comments_count": 0,
      "downvotes_count": 0,
      "event_provider": "",
      "events": [],
      "fake_location?": false,
      "id": 816,
      "inserted_at": "2022-10-29T10:10:31.000000Z",
      "interests": [],
      "location": {
        "coordinates": [
          50.0,
          50.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "media_file_keys": [],
      "place": null,
      "polls": [],
      "post_cost": null,
      "private?": false,
      "title": "voluptatem",
      "type": "offer",
      "universal_link": "http://localhost:4001/posts/ODE2",
      "updated_at": "2022-10-30T10:10:31.000000Z",
      "upvotes_count": 0,
      "user_downvoted?": false,
      "user_upvoted?": false
    }
  ],
  "page_number": 1,
  "page_size": 30
}
```

## Web.TokenController
### <a id=web-tokencontroller-create_token></a>create_token
#### create_token with valid username, phone verified
##### Request
* __Method:__ POST
* __Path:__ /api/token?username=adolphus1970-91&password=randompassword

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBErvovB5-xwAAB4E
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "access": "granted",
  "registration_status": "complete",
  "token": "SFMyNTY.g3QAAAACZAAEZGF0YWIAAAyLZAAGc2lnbmVkbgYAxAxfKIQB.Ydw-3CZMO5pFC5B2Yu-mviRI_xjQE-Sj1DgoWOjDn4A"
}
```

#### create_token with valid username, phone not verified
##### Request
* __Method:__ POST
* __Path:__ /api/token?username=malvina_russel-11&password=randompassword

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA8lYNMgFiUwAACGM
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "access": "granted",
  "registration_status": "phone_verification_required",
  "token": "SFMyNTY.g3QAAAACZAAEZGF0YWIAAAowZAAGc2lnbmVkbgYAfgRfKIQB.aTOr2e8uQRig4IEItZu7Hvk2oX08FaOgK_Axiz7EcFk"
}
```

#### create_token with invalid username
##### Request
* __Method:__ POST
* __Path:__ /api/token?username=wrong&password=randompassword

##### Response
* __Status__: 404
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA_xz2tjENwAAABaI
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "message": "Can't login, invalid credentials or user doesn't exists"
}
```

#### create_token with valid email, phone verified
##### Request
* __Method:__ POST
* __Path:__ /api/token?email=leda_schamberger%40conn.com&password=randompassword

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBJ8JweA79HgAAB1D
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "access": "granted",
  "registration_status": "complete",
  "token": "SFMyNTY.g3QAAAACZAAEZGF0YWIAAA0UZAAGc2lnbmVkbgYAShJfKIQB.4MLfto71xqvOsVKb9NVzfMcYoxywjdXbseHRdy0myNU"
}
```

#### create_token creates followings for user if not initialized
##### Request
* __Method:__ POST
* __Path:__ /api/token?username=henderson2092-38&password=randompassword

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBIJu2dAEJWIAACsC
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "access": "granted",
  "registration_status": "complete",
  "token": "SFMyNTY.g3QAAAACZAAEZGF0YWIAAAy_ZAAGc2lnbmVkbgYAdBBfKIQB.dztveLY2HhZmNRxMsyRNMWM9UTml6hhmPj6pwly0sLs"
}
```

#### create_token does not create followings for user if already initialized
##### Request
* __Method:__ POST
* __Path:__ /api/token?username=esmeralda.gaylord-68&password=randompassword

##### Response
* __Status__: 200
* __Response headers:__
```
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRA5UeswifZVwAABnH
x-version: f30c61431aa2
content-type: application/json; charset=utf-8
```
* __Response body:__
```json
{
  "access": "restricted",
  "registration_status": "complete",
  "token": "SFMyNTY.g3QAAAACZAAEZGF0YWIAAAdoZAAGc2lnbmVkbgYA7gFfKIQB.cqk75FYCki7CNwtlPz_HteL8wzS3XD9pqz7TF5xEhBg"
}
```

## Web.UserController
### <a id=web-usercontroller-show_business_account></a>show_business_account
#### show business account shows business account to owner
##### Request
* __Method:__ GET
* __Path:__ /api/businessAccounts/3168
* __Request headers:__
```
authorization: Bearer oaYfQtkZUxmHWQhJ2JD+
```

##### Response
* __Status__: 200
* __Response headers:__
```
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: FyLRBCdgRgA-ecUAAB3F
x-version: f30c61431aa2
```
* __Response body:__
```json
{
  "avatar": "http://robohash.org/set_set3/bgset_bg1/8PvrCJJtW6ioFNqaIEH",
  "avatar_thumbnail": "http://robohash.org/set_set3/bgset_bg1/8PvrCJJtW6ioFNqaIEH",
  "business_account_name": "Mark",
  "business_account_user_name": "business-colten2058-6",
  "categories": [
    {
      "category": "food",
      "id": 287
    }
  ],
  "email": "hal.powlowski@torphy.net",
  "followers_count": 0,
  "id": 3168,
  "last_name": "Strosin",
  "location": {
    "coordinates": [
      40.0,
      30.0
    ],
    "crs": {
      "properties": {
        "name": "EPSG:4326"
      },
      "type": "name"
    },
    "type": "Point"
  },
  "suggestion": "Smile more!"
}
```

