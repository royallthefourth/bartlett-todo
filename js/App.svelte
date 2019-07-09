<script>
	// TODO fetch set of items
	const items = []
</script>

{#each items as item}
<TodoItem id={item.id} body={item.body} edit=false />
{/each}
