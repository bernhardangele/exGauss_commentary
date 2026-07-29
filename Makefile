.PHONY: all render html pdf typst docx nix-render nix-build split-qs2 clean

# Default target: render all formats
all: render

# Render all formats inside the current environment (e.g. devcontainer)
render:
	cd ms && quarto render ms.qmd

# Render specific formats
html:
	cd ms && quarto render ms.qmd --to apaquarto-html

pdf:
	cd ms && quarto render ms.qmd --to apaquarto-typst

typst:
	cd ms && quarto render ms.qmd --to apaquarto-typst

docx:
	cd ms && quarto render ms.qmd --to apaquarto-docx

# Render using Nix pure shell (from outside the devcontainer)
nix-render:
	nix-shell --pure --run "cd ms && quarto render ms.qmd"

# Build the Nix environment
nix-build:
	nix-build

# Split large .qs2 files into chunks < 99 MB for GitHub upload
split-qs2:
	Rscript split_qs2.R

# Clean up generated manuscript outputs and Quarto cache
clean:
	rm -rf ms/.quarto ms/ms_files ms/ms.html ms/ms.pdf ms/ms.docx

