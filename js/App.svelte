<script>
  import TodoItem from "./TodoItem.svelte";
  import { onMount } from "svelte";
  let items = [];
  let newBody = "";

  onMount(async () => {
    const res = await fetch(`/api/todo?order=date_added.asc`);
    items = await res.json();
  });

  async function addItem() {
    if (newBody.length > 0) {
      let p = await fetch(`/api/todo`, {
        credentials: "same-origin",
        method: "POST",
        body: JSON.stringify([{ body: newBody }])
      });
      await p.json();

      let res = await fetch(`/api/todo?order=date_added.asc`);
      items = await res.json();
      newBody = "";
    }
  }
</script>

{#each items as item}
  <TodoItem id={item.id} body={item.body} edit="false" />
{/each}

<form on:submit|preventDefault={addItem}>
  <input type="text" placeholder="Add a todo" bind:value={newBody} />
  <button>Add</button>
</form>
