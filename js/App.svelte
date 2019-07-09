<script>
    import TodoItem from './TodoItem.svelte';
    import {onMount} from 'svelte';
	let items = [];

    onMount(async () => {
        const res = await fetch(`/api/todo?order=date_added.asc`);
        items = await res.json();
    });
</script>

{#each items as item}
<TodoItem id={item.id} body={item.body} edit=false />
{/each}

<form>
    <input type="text" required placeholder="Add a todo">
    <button>Add</button>
</form>
