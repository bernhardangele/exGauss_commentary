# exGauss_commentary

A short methodological commentary on the use of **Bayesian ex-Gaussian models** for
reaction-time (RT) data in cognitive science.

The paper shows that the parameter labeled `mu` in the **default** `brms` ex-Gaussian
family is *not* the Gaussian location parameter but the mean of the whole
distribution, `E(RT) = μ + τ`. Using a simulated example, it demonstrates how this
can mask a genuine effect on the Gaussian component, and shows how to fit a
**classical** parameterization (via `brms.exgaussian`) that models the conventional
`μ`, `σ`, and `τ` directly.

## Repository structure

```
exGauss_commentary/
├── README.md              ← this file
│
├── ms/                    ← the manuscript project (self-contained)
│   ├── ms.qmd             ← manuscript source (Quarto + R); the file to edit
│   ├── references.bib     ← bibliography (BibTeX)
│   ├── apa.csl            ← APA 7th-edition citation style
│   ├── _quarto.yml        ← Quarto project config: output formats & options
│   ├── _extensions/       ← apaquarto extension (wjschne/apaquarto)
│   │
│   ├── ms.docx            ← rendered Word output        [generated]
│   ├── ms.html            ← rendered HTML output        [generated]
│   └── ms_files/          ← figures/assets for outputs  [generated]
│
```


## What each piece does

| Path | Purpose |
|------|---------|
| `ms/ms.qmd` | The manuscript. Prose + R code chunks that simulate data, fit both the default and classical `brms` ex-Gaussian models, and build the tables. |
| `ms/_quarto.yml` | Declares the project and its output formats (`apaquarto-docx`, `apaquarto-typst`, `apaquarto-html`) plus shared execution options (`echo: true`, project working directory). Because the format lives here, `ms.qmd` needs no `format:` field. |
| `ms/references.bib` | All cited references (software, ex-Gaussian, RT methods). |
| `ms/apa.csl` | Citation Style Language file for APA 7th formatting. |
| `ms/_extensions/wjschne/apaquarto/` | The apaquarto Quarto extension that provides APA-style layout. |

## Reproducing the manuscript

**Requirements**

- [Quarto](https://quarto.org) ≥ 1.4
- R, with the following packages:
  - `brms` — Bayesian regression models
  - `brms.exgaussian` — the classical ex-Gaussian family (`rexgaussian2()`, `exgaussian2()`, `exgaussian2_stancode()`)
  - `cmdstanr` + a working **CmdStan** install — the sampling backend
  - `easystats` (uses `modelbased`) — `estimate_means()` / `estimate_contrasts()`
  - `tinytable` — table formatting

**Render** (from inside `ms/`):

```bash
cd ms
quarto render                              # render every format in _quarto.yml
quarto render ms.qmd --to apaquarto-html   # or just one format
```

Rendering fits two Stan models, so the first run takes a few minutes.

## Notes

- Code chunks are shown in the output (`echo: true`) because the paper is written as a
  tutorial.
- The worked example is a *constructed* scenario: `μ` and `τ` are set to move in
  opposite directions so that the expected RT is identical across conditions, which is
  what makes the default model's null result on `mu` a clear illustration of the pitfall.
