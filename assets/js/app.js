import "phoenix_html";
import Search from "components/Search.svelte";

const app = new Search({
  target: document.querySelector("#search"),
  hydrate: true
});

window.app = app;
