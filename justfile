set windows-shell := ["gnu-tk", "-i", "-c"]
set script-interpreter := ["gnu-tk", "-i", "-l", "sh", "-eu"]
set unstable := true

@help:
    just --list

# Format source code
[group("development")]
format:
    deno fmt *.md
    cd source; just format
    cd docs; just format

# Check source code
[group("development")]
check:
    cd source; just check

# Lint source code
[group("development")]
lint:
    cd source; just lint
