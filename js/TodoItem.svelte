<script>
    export let body = '';
    export let id = '';
    export let edit = false;
</script>

{#if edit}
<form>
    <input type="text" required value={body}>
    <button>Save</button>
</form>
{:else}
<div>
    <span>{body}</span>
    <button>X</button>
</div>
{/if}
