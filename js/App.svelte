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

  function handleDelete(event) {
    items = items.filter(function(item) {
      return item.todo_id !== event.details.todo_id;
    });
  }
</script>

{#each items as item}
  <TodoItem
    todo_id={item.todo_id}
    body={item.body}
    edit="false"
    on:delete={handleDelete} />
{/each}

<form on:submit|preventDefault={addItem}>
  <input type="text" placeholder="Add a todo" bind:value={newBody} />
  <button>Add</button>
</form>
