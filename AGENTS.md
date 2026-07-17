# Agent Guide (AGENTS.md)

This repository contains a reproducible Quarto manuscript analyzing Bayesian ex-Gaussian model parameterizations in `brms`. This document provides automated coding agents with the context, commands, and rules required to work effectively in this repository.

## Repository Overview

- **Project Structure**:
  - `ms/`: Directory for the manuscript.
    - [ms.qmd](file:///workspaces/exGauss_commentary/ms/ms.qmd): The primary manuscript source (Quarto Markdown + R code). Do not edit the generated outputs (`ms.html`, `ms.pdf`, `ms.docx`) directly.
    - [_quarto.yml](file:///workspaces/exGauss_commentary/ms/_quarto.yml): Quarto configuration defining output formats and execution settings.
    - [references.bib](file:///workspaces/exGauss_commentary/ms/references.bib): BibTeX references for citations used in the paper.
  - [Makefile](file:///workspaces/exGauss_commentary/Makefile): Contains commands to render, clean, and manage Nix builds.
  - **Environment Options**:
    - **Devcontainer**: Standard container configuration utilizing a pre-built Docker image (`bangele1/analysis-in-a-box-exg:latest`) with all dependencies (R, Quarto, CmdStan) already set up.
    - **Nix environment (Local Alternative)**:
      - [default.nix](file:///workspaces/exGauss_commentary/default.nix): Nix shell derivation setting up the R environment, TeX live packages, and system packages.
      - [create_env_dev.R](file:///workspaces/exGauss_commentary/create_env_dev.R): R script generating the Nix environment configurations.
      - [install_cmdstan.R](file:///workspaces/exGauss_commentary/install_cmdstan.R): Invoked during Nix shell setup to install CmdStan version `2.37.0`.

## Setup & Build Commands

A [Makefile](file:///workspaces/exGauss_commentary/Makefile) is provided to simplify build commands.

### Option A: Working Inside the Devcontainer (Default/Recommended)
The devcontainer environment is pre-configured. There is **no need** to build or use the Nix environment while working inside the devcontainer.

To render the manuscript directly using `make`:
```bash
make render        # Renders all formats (HTML, PDF, DOCX)
make html          # Renders HTML only
make pdf           # Renders PDF/Typst only
make typst         # Renders PDF/Typst only
make docx          # Renders DOCX only
make clean         # Cleans up Quarto cache and generated files
```

Alternatively, without `make`:
```bash
cd ms
quarto render ms.qmd
```

### Option B: Working Outside the Devcontainer (Nix Environment Alternative)
If you are developing locally outside of the devcontainer, you can use the pure Nix environment.

Using `make`:
```bash
make nix-build     # Builds the Nix environment
make nix-render    # Renders the manuscript inside a pure Nix shell
make clean         # Cleans up Quarto cache and generated files
```

Alternatively, without `make`:
1. **Build the Nix Environment**:
   ```bash
   nix-build
   ```
2. **Enter the Nix Shell**:
   ```bash
   nix-shell --pure
   ```
3. **Render the Manuscript**:
   - From inside the Nix shell:
     ```bash
     cd ms
     quarto render ms.qmd
     ```
   - In a single command:
     ```bash
     nix-shell --pure --run "cd ms && quarto render ms.qmd"
     ```

## Context & Coding Conventions

### Domain Context
- **Ex-Gaussian Distribution**: The distribution is parameterized by:
  - $\mu$ (Gaussian component mean)
  - $\sigma$ (Gaussian component standard deviation)
  - $\tau$ (Exponential component mean/standard deviation)
- **brms Default vs. Classical**:
  - **Default `brms::exgaussian`**: The `mu` parameter represents the mean of the entire distribution ($E(RT) = \mu + \tau$).
  - **Classical `brms.exgaussian`**: Fits the conventional parameterization directly, where $\mu$ is only the mean of the Gaussian component.

### Formatting & Coding Style
- Write Quarto chunks with R syntax.
- Maintain code execution and formatting options set in `ms.qmd` headers and `_quarto.yml`.
- Keep prose academic, clear, and focused on the methodological points.
- Ensure bibliography entries are formatted properly in `references.bib`.

## Verification & Testing Procedures

Before finalizing any changes to the manuscript or code:
1. Run a full render of the manuscript.
   - If in the devcontainer: `cd ms && quarto render ms.qmd`
   - If outside: `nix-shell --pure --run "cd ms && quarto render ms.qmd"`
2. Check that the build completes with exit code 0.
3. Ensure no model compilation or sampling errors occur in the R chunks (fits default and classical ex-Gaussian models via `cmdstanr`).
4. Verify that generated files (`ms.html`, `ms.pdf`, and `ms.docx`) compile successfully without formatting warnings.
