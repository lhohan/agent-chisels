# List available skills

This prompt outputs the available skills in a strictly prescribed format. 

## Output format (strict)

- Emit bullets only; do not extra commentary.
- One skill per line: name
- Use '*' as icon.
- Sort rows lexicographically by skill name.
- If no skills are found, emit "No agent skills found.".

## Example

```
* review-code
* check-open-changes
```

## Procedure

1. Ask yourself: "What skills are available?". Do NOT inspect the file system directly.
2. Output each skills per out format specified above
