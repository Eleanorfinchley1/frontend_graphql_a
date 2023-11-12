## About channels/websockets

You probably would want to use a client library like [sjrmanning/Birdsong](https://github.com/sjrmanning/Birdsong) (if you are developing for ios).

When you connect, you have to provide an `auth_token` (same one as for django api) of the user.

### chat channel

When you are joining a chat room channel, you have to provide the chat room id (TODO maybe change to chat room key) that you are trying to connect to.

To post a message, send something like

```json
{
  "message": "Message Here",
  "media_file_keys": [...] // optional, [] by default
  "message_type": "TXT",
  "location": {"type": "Point", "coordinates": [-96.876369, 29.90532]} // also optional
}
```

to a topic `"message:new"`. The new messages are received on `"message:new"` topic as well.

See tests in `test/web/channels/chat_channel_test.exs` for more.

### posts channel

Join `"posts"` channel with user's current location (geometry + radius) and a post types list
("vote", "event", "regular", and "poll" are supported):

```json
// Example json payload
{
  "geometry": {
    "type": "Point",
    "coordinates": [40.5, -50.0]
  },
  "radius": 1000,
  "post_types": ["regular"]
}
```

```swift
// swift example using birdsong
let payload = [
  "geometry": ["type": "Point", "coordinates": [40.5, -50.0]],
  "radius": 1000,
  "post_types": ["regular"]
]
let channel = socket.channel("posts", payload: payload)
channel.join()
  .receive("ok") { _ in } // joined
  .receive("error") { payload in // couldn't join
    guard let response = payload["response"] as? [String: Any],
      let errorDetail = response["details"] as? String else {
        return
    }
    print(errorDetail)
  }
```

to automacitally subscribe for new public posts of that type near that location
by listening to events with `"post:new"`, `"post:update"`, and `"post:delete"` as their topic.

```swift
channel.on("post:new") { payload in
  // ...
}

channel.on("post:update") { payload in
  // ...
}

channel.on("post:delete") { payload in
  // ...
}
```

You can change the current location and post_type of the channel by sending a message
with `"update"` topic

In this example all channel assigns are changed:

```json
// example json payload
{
  "geometry": {
    "type": "Point",
    "coordinates": [10.5, -10.0]
  },
  "radius": 500,
  "post_types": ["vote", "poll"]
}
```

```swift
// swift example using birdsong
let updates = [
  "geometry": ["type": "Point", "coordinates": [10.5, -10.0]],
  "radius": 500,
  "post_types": ["vote", "poll"]
]
channel.send("update", payload: updates)
  .receive("ok") { _ in } // updated
  .receive("error") { _ in } // couldn't update (shouldn't happen if the inputs are valid)
```

And here we only change the post type:

```json
// example json payload
{
  "post_types": ["vote", "poll"]
}
```

```swift
// swift example using birdsong
channel.send("update", payload: ["post_types": ["vote", "poll"]])
  .receive("ok") { _ in } // updated
  .receive("error") { _ in } // couldn't update (shouldn't happen if the inputs are valid)
```

You can also query posts by sending a message to `"posts:list"`topic with

```json
// example json payload
{
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [40.5, -50.0],
        [40.5, -55.0],
        [50.7, -55.0],
        [50.7, -50.0],
        [40.5, -50.0]
      ]
    ]
  }
}
```

```swift
// swift example
let payload = [
    "geometry": [
        "type": "Polygon",
        "coordinates": [[
          [40.5, -50.0],
          [40.5, -55.0],
          [50.7, -55.0],
          [50.7, -50.0],
          [40.5, -50.0]
        ]]
    ]
]
channel.send("posts:list", payload: payload)
  .receive("ok") { [weak self] response in
      // parse response, etc.
  }
  .receive("error") { _ in } // shouldn't happen if the inputs are valid
```

or

```json
{
  "geometry": {
    "type": "Point",
    "coordinates": [40.5, -50.0]
  }
  // can optionally provide "radius"
}
```

To get post statistics for some posts, send a message with `"posts:statistics"` topic and payload like

```json
{
  "post_ids": [1, 3, 4, 5, 6, 2354, 3456, 3457]
}
```

```swift
// swift example
channel.send("posts:statistics", payload: ["post_ids": [1, 3, 4, 5, 6, 2354, 3456, 3457]])
  .receive("ok") { [weak self] response in
      // parse response, etc.
  }
  .receive("error") { _ in } // shouldn't happen if the inputs are valid
```

See tests for `test/web/channels/post_channel_test.exs`

## Dropchat channel

Join `"dropchats"` channel with user's current location (geometry + radius):

```json
// Example json payload
{
  "geometry": {
    "type": "Point",
    "coordinates": [40.5, -50.0]
  },
  "radius": 1000
}
```

```swift
// swift example using birdsong
let payload = [
  "geometry": ["type": "Point", "coordinates": [40.5, -50.0]],
  "radius": 1000
]
let channel = socket.channel("dropchats", payload: payload)
channel.join()
  .receive("ok") { _ in } // joined
  .receive("error") { payload in // couldn't join
    guard let response = payload["response"] as? [String: Any],
      let errorDetail = response["details"] as? String else {
        return
    }
    print(errorDetail)
  }
```

to automacitally subscribe for new public posts of that type near that location
by listening to events with `"dropchat:new"` as their topic.

```swift
channel.on("dropchat:new") { payload in
  // ...
}
```

You can change the current location of the channel by sending a message
with `"update"` topic

In this example all channel assigns are changed:

```json
// example json payload
{
  "geometry": {
    "type": "Point",
    "coordinates": [10.5, -10.0]
  },
  "radius": 500
}
```

```swift
// swift example using birdsong
let updates = [
  "geometry": ["type": "Point", "coordinates": [10.5, -10.0]],
  "radius": 500
]
channel.send("update", payload: updates)
  .receive("ok") { _ in } // updated
  .receive("error") { _ in } // couldn't update (shouldn't happen if the inputs are valid)
```

And here we only change the radius:

```json
// example json payload
{
  "radius": 500
}
```

```swift
// swift example using birdsong
channel.send("update", payload: ["radius": 500]])
  .receive("ok") { _ in } // updated
  .receive("error") { _ in } // couldn't update (shouldn't happen if the inputs are valid)
```

You can also query dropchats by sending a message to `"dropchats:list"`topic with

```json
// example json payload
{
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [40.5, -50.0],
        [40.5, -55.0],
        [50.7, -55.0],
        [50.7, -50.0],
        [40.5, -50.0]
      ]
    ]
  }
}
```

```swift
// swift example
let payload = [
    "geometry": [
        "type": "Polygon",
        "coordinates": [[
          [40.5, -50.0],
          [40.5, -55.0],
          [50.7, -55.0],
          [50.7, -50.0],
          [40.5, -50.0]
        ]]
    ]
]
channel.send("dropchats:list", payload: payload)
  .receive("ok") { [weak self] response in
      // parse response, etc.
  }
  .receive("error") { _ in } // shouldn't happen if the inputs are valid
```

or

```json
{
  "geometry": {
    "type": "Point",
    "coordinates": [40.5, -50.0]
  }
  // can optionally provide "radius"
}
```

See tests for `test/web/channels/dropchat_channel_test.exs`

### livestream channel

"comments:list" event with return in reply -

```json
{
  "comments": [
    {
      "author": "username",
      "body": "hello",
      "current_user_downvote": 0,
      "current_user_upvote": 1,
      "downvote": 4,
      "id": "comment_id",
      "upvote": 1
    },
    {
      "author": "username",
      "body": "hello2",
      "current_user_downvote": 1,
      "current_user_upvote": 0,
      "downvote": 2,
      "id": "comment_id",
      "upvote": 3
    }
  ]
}
```

"comment_vote:new" event with params

```json
{ "comment_id": "comment_id", "vote_type": "v_type" }
```

where v_type in ["upvote", "downvote", ""] will create a new comment vote with given type and broadcast a "comment:change_votes" event with updated votes count for that comment as:

```json
{ "comment_id": "comment_id", "downvotes": 0, "upvotes": 1 }
```

"vote:new" event with params

```json
{ "vote_type": "v_type" }
```

where v_type in ["upvote", "downvote", ""] will create a new livestream vote with given type and broadcast a "change_votes" event with updated votes count for that livestream as:

```json
{ "downvotes": 0, "upvotes": 1 }
```

to remove vote of any type send an empty string as v_type

if you upvote and change you mind to downvote you don't have to remove upvote first, just send a new type

"livestream:info" event

```json
{ "online_viewers_count": 1, "views_count": 2 }
```
