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

## Troubleshooting & Lessons Learned

### 1. LaTeX Escaping in Quarto YAML options
* **Symptom**: `ERROR: YAMLException: unknown escape sequence` during rendering.
* **Cause**: Double-quoted strings in YAML chunk options (like `#| tbl-cap: "..."` or `#| fig-cap: "..."`) interpret LaTeX backslashes as escape characters. For instance, `\mu` and `\tau` will trigger parsing errors because `\m` is not a valid escape sequence.
* **Fix**: Use double backslashes (`\\mu` and `\\tau`) inside double quotes, or wrap the caption in single quotes (`'...'`), which do not evaluate backslash escapes.

### 2. Numeric Initialization for Hierarchical ex-Gaussian Models
* **Symptom**: `Chain Rejecting initial value: Log probability evaluates to log(0), i.e. negative infinity` or chains failing to start completely.
* **Cause**: In complex ex-Gaussian models with hierarchical random effects, `tau` and `sigma` use log links to enforce positive values. Stan's default unconstrained random initialization in `[-2, 2]` causes group SD parameters to exponentiate (up to $e^2 \approx 7.3$). When subject random effects are drawn from $\mathcal{N}(0, 7.3)$, they blow up exponentially, creating extreme tail values (e.g. $e^{10} \approx 22,000\text{ ms}$) that cause numerical underflow/overflow.
* **Fix**: Provide a complete initialization function (`inits = init_classical`) that specifies sensible start values for all parameters in the `parameters` block, particularly setting:
  - Identity link intercept (`Intercept = 500`)
  - Log link intercepts (`Intercept_sigma = log(60)` and `Intercept_tau = log(100)`)
  - Log-scale random effects standard deviations (`sd_3 = rep(0.1, 4)` and `sd_4 = rep(0.1, 4)`) to very small values.
  - Standardized random effects (`z_1` to `z_4`) to matrices of exactly 0.
  - Cholesky correlation factors (`L_1` to `L_4`) to identity matrices.

### 3. Dynamic Random Effect Dimension Mapping
* **Symptom**: Dimension mismatch error on parameters like `z_2` or `z_4` (e.g., `dims declared=(4,240); dims found=(4,480)`).
* **Cause**: The number of grouping levels (unique subjects and items) passed in initial values must exactly match the grouping levels in the filtered dataset passed to `brm()`. For example, filtering data to words only (excluding non-words) changes the count of unique targets.
* **Fix**: Calculate grouping level dimensions (e.g., `N_source` and `N_target`) *after* subsetting/filtering the dataset:
  ```R
  data_fit <- exp2_data_to_include %>% filter(corr == 1 & StimulusType == "Word" & rt > 250 & rt < 1800)
  N_source <- length(unique(data_fit$source))
  N_target <- length(unique(data_fit$Target))
  ```

### 4. Large Model Serialization
* **Symptom**: Model fit objects are extremely large (~290MB) and hit GitHub file limits.
* **Fix**: Use `library(qs2)` and `qs_save(fit, "path.qs2")` for highly compressed and fast R object serialization, and ensure `*.qs2` is added to `.gitignore`.

