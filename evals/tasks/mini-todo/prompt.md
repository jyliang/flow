# Prompt

Pass this verbatim to `/flow:flow`:

> Build a single-file Python TODO CLI named `todo`. It stores tasks in a JSON file (default: `~/.todo.json`, override via `--file`). Commands:
>
> - `todo add "<text>"` — append a new task, print its id and text
> - `todo ls` — list tasks, one per line, with `[ ]` / `[x]` and the id
> - `todo done <id>` — mark complete
> - `todo rm <id>` — delete
>
> Use only the Python standard library. Single file is fine. Include a short README with install + usage.
