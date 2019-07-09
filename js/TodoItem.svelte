<script>
  import { createEventDispatcher } from "svelte";

  const dispatch = createEventDispatcher();

  export let body = "";
  export let todo_id = null;

  let edit = false;

  function enableEdit() {
    edit = true;
  }

  async function saveItem() {
    edit = false;
    await fetch("/api/todo?todo_id=eq." + todo_id, {
      credentials: "same-origin",
      method: "PATCH",
      body: JSON.stringify([{ body: body }])
    });
  }

  async function deleteItem() {
    let p = await fetch("/api/todo?todo_id=eq." + todo_id, {
      credentials: "same-origin",
      method: "DELETE"
    });
    if (p.ok) {
      dispatch("delete", {
        todo_id: todo_id
      });
    }
  }
</script>

{#if edit == true}
  <form on:submit|preventDefault={saveItem}>
    <input type="text" required bind:value={body} />
    <button>Save</button>
  </form>
{:else}
  <div>
    <span on:click={enableEdit}>{body}</span>
    <button on:click={deleteItem}>X</button>
  </div>
{/if}
