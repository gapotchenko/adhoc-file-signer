[windows]
set shell := ["gnu-tk", "-i", "-c"]
[windows]
set script-interpreter := ["gnu-tk", "-i", "-l", "sh", "-eu"]

# -----------------------------------------------------------------------------

@help:
    just --list

# -----------------------------------------------------------------------------
# Development
# -----------------------------------------------------------------------------

# Format source code
[group("development")]
format:
    just --fmt
    deno fmt *.md
    cd .github; deno fmt **/*.yml
    cd source; just format
    cd docs; just format

# Check source code
[group("development")]
check:
    cd source; just check
    cd docs; just check

# Lint source code
[group("development")]
lint:
    cd source; just lint

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

[group("build")]
pack:
    cd source; just pack

[group("build")]
clean:
    cd source; just clean
