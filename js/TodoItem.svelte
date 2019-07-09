<script>
    export let body = '';
    export let id = '';
    export let edit = false;

    function enableEdit() {
      edit = true
    }

    function saveItem() {
      edit = false
      // TODO patch item body back to server
    }

    function deleteItem() {
      // TODO send delete request
      // TODO delete this element?
    }
</script>

{#if edit}
<form on:submit|preventDefault={saveItem}>
    <input type="text" required bind:value={body}>
    <button>Save</button>
</form>
{:else}
<div>
    <span on:click={enableEdit}>{body}</span>
    <button on:click={deleteItem}>X</button>
</div>
{/if}
