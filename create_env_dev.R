#need this to set path to nix for some reason
# Sys.setenv(PATH = paste("/nix/var/nix/profiles/default/bin", Sys.getenv("PATH"), sep=":"))

required_packages <- c(
  "tidyverse",
  "fs",
  "brms",
  "ggplot2",
  "ggdist",
  "tinytable",
  "patchwork",
  "knitr",
  "rmarkdown",
  "marginaleffects",
  "reformulas",
  "collapse",
  "ragg",
  "qs2",
  "emmeans"
)

library(rix)

rix(
  date = "2026-06-22",
  r_pkgs = required_packages,
  system_pkgs = c(
    "quarto",
    "git",
    "pandoc",
    "typst",
    "stanc",
    "tbb",
    "gettext",
    "libintl"
  ),
  git_pkgs = list(
    list(
      package_name = "cmdstanr",
      repo_url = "https://github.com/stan-dev/cmdstanr",
      commit = "541f36c74c236a322eaa0908e2e86425790ca2cf"
    ),
    list(
      package_name = "insight",
      repo_url = "https://github.com/easystats/insight",
      commit = "36917c3bedfadf901ea8b0a90c5e144ae82bcfb8"
    ),
    list(
      package_name = "datawizard",
      repo_url = "https://github.com/easystats/datawizard",
      commit = "b651172a20c86aca0d768b44a634c83fb146cafd"
    ),
    list(
      package_name = "bayestestR",
      repo_url = "https://github.com/easystats/bayestestR",
      commit = "77d649a2f55481e0b863c0d35b2a14dba7f44afb"
    ),
    list(
      package_name = "parameters",
      repo_url = "https://github.com/easystats/parameters",
      commit = "9fb4f21f2452cfb1c8e6511e0cfa521db5d7d7de"
    ),
    list(
      package_name = "performance",
      repo_url = "https://github.com/easystats/performance",
      commit = "78c41eec5285896e8ae86776979ff7b4f41f38ae"
    ),
    list(
      package_name = "modelbased",
      repo_url = "https://github.com/easystats/modelbased",
      commit = "e12e4a96c396b754a6b29c1df3215c1c0057e287"
    ),
    list(
      package_name = "cogmod",
      repo_url = "https://github.com/DominiqueMakowski/cogmod",
      commit = "4b10ea5e00e02984d39c0749adf8dc0b9c4ab15b"
    )
  ),
  tex_pkgs = c(
    "amsmath",
    "ninecolors",
    "apa7",
    "scalerel",
    "threeparttable",
    "threeparttablex",
    "endfloat",
    "environ",
    "multirow",
    "tcolorbox",
    "pdfcol",
    "tikzfill",
    "fontawesome5",
    "framed",
    "newtx",
    "fontaxes",
    "xstring",
    "wrapfig",
    "tabularray",
    "siunitx",
    "fvextra",
    "geometry",
    "setspace",
    "fancyvrb",
    "anyfontsize"
  ),
  shell_hook = "Rscript install_cmdstan.R",
  ide = "positron",
  project_path = ".",
  overwrite = TRUE
)
