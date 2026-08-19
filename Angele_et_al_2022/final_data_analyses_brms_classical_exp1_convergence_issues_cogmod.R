# final_data_analyses_brms_classical_exp1_convergence_issues_cogmod.R
# Applies the classical ex-Gaussian parameterization (via {cogmod} default softplus link)
# to Exp 1 RT data to demonstrate convergence issues with softplus link.
# Reference: Angele et al. (2022) Experiment 1

library(tidyverse)
library(brms)
library(cogmod)
library(qs2)

# -------------------------------------------------------------------------
# 1. Setup Classical Ex-Gaussian Family ({cogmod})
# -------------------------------------------------------------------------
# Uses cogmod's rt_exgaussian() family and rt_exgaussian_stanvars().
# In this classical parameterization:
#   - mu is the location parameter of the Gaussian component (softplus link)
#   - tau is the mean of the exponential component (softplus link, response scale)
#   - sigma is the SD of the Gaussian component (softplus link, response scale)

# -------------------------------------------------------------------------
# 2. Load Exp 1 Data
# -------------------------------------------------------------------------
# Loads the single preprocessed dataset file (exp1_data.qs2).
data_path <- if (file.exists("Angele_et_al_2022/exp1_data.qs2")) {
  "Angele_et_al_2022/exp1_data.qs2"
} else if (file.exists("exp1_data.qs2")) {
  "exp1_data.qs2"
} else if (file.exists("../Angele_et_al_2022/exp1_data.qs2")) {
  "../Angele_et_al_2022/exp1_data.qs2"
} else {
  "exp1_data.qs2"
}

exp1_data_to_include <- qs_read(data_path)

# -------------------------------------------------------------------------
# 3. Contrast Coding
# -------------------------------------------------------------------------
contrasts(exp1_data_to_include$Condition) <- c(-.5, .5)
contrasts(exp1_data_to_include$PrimeDuration) <- c(-.5, .5)

# -------------------------------------------------------------------------
# 4. Prior Specification
# -------------------------------------------------------------------------
# Setting priors for the classical model (via {cogmod}):
#   - mu submodel (softplus link): typical RT intercept centered around 0.5 s, effects centered around 0.
#   - tau submodel (softplus link): response scale intercept centered around 0.1 s, effects centered around 0.
#   - sigma submodel (softplus link): response scale intercept centered around 0.06 s.
priors_classical <- c(
  # Gaussian location mu (in seconds)
  prior(normal(0.5, 0.2), class = "Intercept"),
  prior(normal(0, 0.1), class = "b"),
  
  # Exponential tail tau (in seconds)
  prior(normal(0.1, 0.1), class = "Intercept", dpar = "tau"),
  prior(normal(0, 0.1), class = "b", dpar = "tau"),
  
  # Gaussian SD sigma (in seconds)
  prior(normal(0.06, 0.05), class = "Intercept", dpar = "sigma"),

  # Half-Student-t priors on random effect SDs (scale = 0.2 s = 200 ms)
  prior(student_t(3, 0, 0.2), class = "sd"),
  prior(student_t(3, 0, 0.2), class = "sd", dpar = "tau")
)

# -------------------------------------------------------------------------
# 5. Initialization Function
# -------------------------------------------------------------------------
# Filter the dataset first to match the exact subset of data passed to brm().
# This ensures that the number of unique sources (participants) and targets
# used for initial value dimensions matches what Stan declares.
data_fit <- exp1_data_to_include %>% 
  filter(corr == 1 & StimulusType == "Word" & rt > 0.250 & rt < 1.800)

N_source <- length(unique(data_fit$source))
N_target <- length(unique(data_fit$Target))

init_classical <- function() {
  list(
    Intercept = 0.5,        # Gaussian location component (softplus link)
    Intercept_sigma = 0.060,   # Gaussian SD (response scale, softplus link)
    Intercept_tau = 0.1,    # Exponential tail (response scale, softplus link)
    b = rep(0, 3),          # Population-level effects on mu
    b_tau = rep(0, 3),      # Population-level effects on tau
    sd_1 = rep(0.1, 4),     # Subject-level SDs for mu (in seconds)
    sd_2 = rep(0.1, 4),     # Target-level SDs for mu (in seconds)
    sd_3 = rep(0.1, 4),     # Subject-level SDs for tau (in seconds)
    sd_4 = rep(0.1, 4),     # Target-level SDs for tau (in seconds)
    z_1 = matrix(0, nrow = 4, ncol = N_source),
    z_2 = matrix(0, nrow = 4, ncol = N_target),
    z_3 = matrix(0, nrow = 4, ncol = N_source),
    z_4 = matrix(0, nrow = 4, ncol = N_target),
    L_1 = diag(4),
    L_2 = diag(4),
    L_3 = diag(4),
    L_4 = diag(4)
  )
}

# -------------------------------------------------------------------------
# 6. Fit Classical Ex-Gaussian model
# -------------------------------------------------------------------------
# Submodels:
#   - rt (mu): Gaussian location parameter
#   - tau: Exponential component (tail)
#   - sigma: Gaussian standard deviation (kept constant across conditions using ~ 1)
blmm_exp1_classical_rt <- brm(
  data = data_fit, 
  formula = bf(
    rt ~ Condition * PrimeDuration + (1 + Condition * PrimeDuration|source) + (1 + Condition * PrimeDuration|Target), 
    tau ~ Condition * PrimeDuration + (1 + Condition * PrimeDuration|source) + (1 + Condition * PrimeDuration|Target),
    sigma ~ 1
  ),
  warmup = 1000,
  iter = 5000,
  chains = 4,
  prior = priors_classical,
  family = rt_exgaussian(),
  stanvars = rt_exgaussian_stanvars(),
  init = 0,
  cores = 4, 
  backend = "cmdstanr", 
  threads = threading(2)
)

# Save the classical model output
output_file <- if (dir.exists("Angele_et_al_2022")) {
  "Angele_et_al_2022/blmm_exp1_convergence_issues_cogmod.qs2"
} else {
  "blmm_exp1_convergence_issues_cogmod.qs2"
}
qs_save(blmm_exp1_classical_rt, file = output_file)
