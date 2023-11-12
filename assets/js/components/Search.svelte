<input bind:value=query class="input-reset ba b--black-20 pa2 mb2 db w-100">

{#if users.length != 0}
  <h3 class="f4 bold center mw6">Users:</h3>
  <ul class="list pl0 ml0 center mw6">
    {#each users as user}
      <li>
        <div class="ba ph3">
          <p><strong>id:</strong> {user.id}</p>
          <p><strong>username:</strong> {user.username}</p>
        </div>
      </li>
    {/each}
  </ul>
{/if}

{#if chatRooms.length != 0}
  <h3 class="f4 bold center mw6">Chat rooms:</h3>
  <ul class="list pl0 ml0 center mw6">
    {#each chatRooms as chatRoom}
      <li>
        <div class="ba ph3">
          <p><strong>id:</strong> {chatRoom.id}</p>
          <p><strong>title:</strong> {chatRoom.title}</p>
        </div>
      </li>
    {/each}
  </ul>
{/if}

{#if chatRoomMessages.length != 0}
  <h3 class="f4 bold center mw6">Chat room messages:</h3>
  <ul class="list pl0 ml0 center mw6">
    {#each chatRoomMessages as chatRoomMessage}
      <li>
        <div class="ba ph3">
          <p><strong>id:</strong> {chatRoomMessage.id}</p>
          <p><strong>message:</strong> {chatRoomMessage.message}</p>
          <p><strong>room id:</strong> {chatRoomMessage.room.id}</p>
          <p><strong>room title:</strong> {chatRoomMessage.room.title}</p>
        </div>
      </li>
    {/each}
  </ul>
{/if}

{#if posts.length != 0}
  <h3 class="f4 bold center mw6">Posts:</h3>
  <ul class="list pl0 ml0 center mw6">
    {#each posts as post}
      <li>
        <div class="ba ph3">
          <p><strong>id:</strong> {post.id}</p>
          <p><strong>title:</strong> {post.title}</p>
          <p><strong>body:</strong> {post.body}</p>
        </div>
      </li>
    {/each}
  </ul>
{/if}

{#if postComments.length != 0}
  <h3 class="f4 bold center mw6">Post comments:</h3>
  <ul class="list pl0 ml0 center mw6">
    {#each postComments as postComment}
      <li>
        <div class="ba ph3">
          <p><strong>id:</strong> {postComment.id}</p>
          <p><strong>comment:</strong> {postComment.comment}</p>
          <p><strong>post id:</strong> {postComment.post.id}</p>
          <p><strong>post title:</strong> {postComment.post.title}</p>
        </div>
      </li>
    {/each}
  </ul>
{/if}

<script>
import { Socket } from "phoenix";

let socket = new Socket("/socket", {
  params: {
    token: window.userToken,
    logger: (kind, msg, data) => {
      console.log(`${kind}: ${msg}`, data);
    }
  }
});
socket.connect();

let channel = socket.channel("search", {});
channel
  .join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp);
  })
  .receive("error", resp => {
    console.log("Unable to join", resp);
  });

export default {
  onstate({ changed, current, previous }) {
    if (previous && previous.query != current.query) {
      channel.push("search", { query: current.query }).receive("ok", resp => {
        this.set({
          users: resp["users"],
          chatRooms: resp["chat_rooms"],
          chatRoomMessages: resp["chat_room_messages"],
          posts: resp["posts"],
          postComments: resp["post_comments"]
        });
      });
    }
  },

  data() {
    return {
      query: "",
      users: [],
      chatRooms: [],
      chatRoomMessages: [],
      posts: [],
      postComments: []
    };
  }
};
</script>
