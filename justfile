set windows-shell := ["gnu-tk", "-i", "-c"]
set script-interpreter := ["gnu-tk", "-i", "-l", "sh", "-eu"]
set unstable := true

@help:
    just --list

# Format source code
format:
    deno fmt *.md
    cd source; just format
