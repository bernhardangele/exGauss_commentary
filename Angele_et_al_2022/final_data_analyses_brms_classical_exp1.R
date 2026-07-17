# final_data_analyses_brms_classical_exp1.R
# Applies the classical ex-Gaussian parameterization (via {brms.exgaussian}) to Exp 1 RT data.
# This script is prepared according to the Geller methodology described in ms.qmd.
# Reference: Angele et al. (2022) Experiment 1

library(tidyverse)
library(brms)
library(brms.exgaussian)
library(qs2)

# -------------------------------------------------------------------------
# 1. Setup Custom Classical Ex-Gaussian Family
# -------------------------------------------------------------------------
# Setup custom ex-Gaussian Stan functions and family definition.
exg_stanvars <- exgaussian2_stancode()
exg_family <- exgaussian2()

# -------------------------------------------------------------------------
# 2. Load and Filter Exp 1 Data
# -------------------------------------------------------------------------
# Note: Run this script with the working directory set to the folder containing this script.
# (i.e. /workspaces/exGauss_commentary)
exp1_all_participants <- read_csv("Angele_et_al_2022/participant_data_exp1.csv")

exp1 <- fs::dir_ls(path = "Angele_et_al_2022/data_exp1", glob = "*.csv") %>%
  map_dfr(read_csv, .id = "source", col_type = cols(
    .default = col_character(), 
    rt = col_double(), 
    corr = col_integer(), 
    TrialID = col_integer()
  )) %>% 
  filter(!is.na(TrialID) & TrialID < 1000) %>%
  select(source, participant, date, OS, frameRate, rt, corr, TrialID, StimulusType, Condition, PrimeDuration, Prime, Target)

exp1$device <- ifelse(exp1$OS %in% c("Linux armv7l", "Linux armv8l"), "android", "computer")

# Only consider valid participants (filtering out duplicates, ages of 99, etc.)
exp1_actual_participants <- filter(
  exp1_all_participants, 
  (PROLIFIC_PID %in% exp1$participant) & 
  (nchar(PROLIFIC_PID) == 24) & 
  !(PROLIFIC_PID %in% c("5fa3b4abbcfd0b6c243758bc")) & 
  (`What is your age?` != 99) & 
  (`Response ID` != "R_sU4qJ6UCe9jRKs9")
)

# Filtering participants based on accuracy (>= 80% correct) and full completion (480 trials)
exp1_accuracy_by_participant <- exp1 %>% 
  filter(participant %in% exp1_actual_participants$PROLIFIC_PID) %>% 
  group_by(source) %>% 
  summarise(acc = mean(corr == 1), N = n())

exp1_participants_to_include <- exp1_accuracy_by_participant %>% 
  filter(N == 480 & acc >= .8)

exp1_data_to_include <- exp1 %>% 
  filter(source %in% exp1_participants_to_include$source & participant %in% exp1_actual_participants$PROLIFIC_PID) %>% 
  mutate(
    StimulusType = StimulusType %>% factor(levels = c("NW", "WORD"), labels = c("Nonword", "Word")), 
    Condition = Condition %>% factor(levels = c("ID", "UN"), labels = c("Identical", "Unrelated")), 
    PrimeDuration = PrimeDuration %>% factor(levels = c(33, 50), labels = c("33 ms", "50 ms")), 
    rt = rt * 1000 # Convert RT to milliseconds
  )

# -------------------------------------------------------------------------
# 3. Contrast Coding
# -------------------------------------------------------------------------
contrasts(exp1_data_to_include$Condition) <- c(-.5, .5)
contrasts(exp1_data_to_include$PrimeDuration) <- c(-.5, .5)

# -------------------------------------------------------------------------
# 4. Prior Specification
# -------------------------------------------------------------------------
# Setting priors for the classical model:
#   - mu submodel (identity link): typical RT intercept centered around 500 ms, effects centered around 0.
#   - tau submodel (log link): log(intercept) centered around log(100), effects centered around 0.
#   - sigma submodel (log link): log(intercept) centered around log(60).
priors_classical <- c(
  # Gaussian location mu: Intercept & effects
  prior(normal(500, 100), class = "Intercept"),
  prior(normal(0, 100), class = "b", coef = "Condition1"),
  prior(normal(0, 100), class = "b", coef = "PrimeDuration1"),
  prior(normal(0, 100), class = "b", coef = "Condition1:PrimeDuration1"),
  
  # Exponential tail tau (on log scale): Intercept & effects
  prior(normal(log(100), 0.5), class = "Intercept", dpar = "tau"),
  prior(normal(0, 0.5), class = "b", dpar = "tau"),
  
  # Gaussian SD sigma (on log scale): Intercept
  prior(normal(log(60), 0.5), class = "Intercept", dpar = "sigma")
)

# -------------------------------------------------------------------------
# 5. Initialization Function
# -------------------------------------------------------------------------
# Filter the dataset first to match the exact subset of data passed to brm().
# This ensures that the number of unique sources (participants) and targets
# used for initial value dimensions matches what Stan declares.
data_fit <- exp1_data_to_include %>% 
  filter(corr == 1 & StimulusType == "Word" & rt > 250 & rt < 1800)

N_source <- length(unique(data_fit$source))
N_target <- length(unique(data_fit$Target))

# A complete function to generate sensible initial values for all parameters.
# Standard random initialization can draw massive standard deviations on the log scale
# (e.g. for tau, exp(7.3) ≈ 1400x multiplier), which overflows/underflows the likelihood.
# We initialize all intercepts, coefficients, standard deviations, standardized random effects,
# and Cholesky correlation factors to highly stable starting values.
init_classical <- function() {
  list(
    Intercept = 500,        # Gaussian location component (identity link)
    Intercept_sigma = log(60), # Gaussian SD (log link)
    Intercept_tau = log(100),  # Exponential tail (log link)
    b = rep(0, 3),          # Population-level effects on mu
    b_tau = rep(0, 3),      # Population-level effects on tau
    sd_1 = rep(30, 4),      # Subject-level SDs for mu (identity scale, in ms)
    sd_2 = rep(30, 4),      # Target-level SDs for mu (identity scale, in ms)
    sd_3 = rep(0.1, 4),     # Subject-level SDs for tau (log scale, small to prevent overflow)
    sd_4 = rep(0.1, 4),     # Target-level SDs for tau (log scale, small to prevent overflow)
    z_1 = matrix(0, nrow = 4, ncol = N_source),  # Standardized random effects for source (mu)
    z_2 = matrix(0, nrow = 4, ncol = N_target),  # Standardized random effects for Target (mu)
    z_3 = matrix(0, nrow = 4, ncol = N_source),  # Standardized random effects for source (tau)
    z_4 = matrix(0, nrow = 4, ncol = N_target),  # Standardized random effects for Target (tau)
    L_1 = diag(4),          # Cholesky factor of correlation matrix for source (mu)
    L_2 = diag(4),          # Cholesky factor of correlation matrix for Target (mu)
    L_3 = diag(4),          # Cholesky factor of correlation matrix for source (tau)
    L_4 = diag(4)           # Cholesky factor of correlation matrix for Target (tau)
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
  family = exg_family,
  stanvars = exg_stanvars,
  inits = init_classical,
  #control = list(adapt_delta = 0.95),
  cores = 4, 
  backend = "cmdstanr", 
  threads = threading(2)
)

# Save the classical model output
qs_save(blmm_exp1_classical_rt, file = "Angele_et_al_2022/blmm_exp1_classical_rt.qs2")
