# prepare_exp1_data.R
# Preprocesses raw Exp 1 PsychoJS trial CSVs and Qualtrics survey data,
# filtering valid participants (accuracy >= 80%, completed 480 trials),
# setting factor levels and contrasts, and saving to a single compact .qs2 file.

library(tidyverse)
library(qs2)

cat("Reading Qualtrics participant metadata...\n")
exp1_all_participants <- read_csv("Angele_et_al_2022/participant_data_exp1.csv", show_col_types = FALSE)

cat("Reading raw trial data CSVs from Angele_et_al_2022/data_exp1...\n")
exp1_raw <- fs::dir_ls(path = "Angele_et_al_2022/data_exp1", glob = "*.csv") %>%
  map_dfr(read_csv, .id = "source", col_type = cols(
    .default = col_character(), 
    rt = col_double(), 
    corr = col_integer(), 
    TrialID = col_integer()
  )) %>% 
  filter(!is.na(TrialID) & TrialID < 1000) %>%
  select(source, participant, date, OS, frameRate, rt, corr, TrialID, StimulusType, Condition, PrimeDuration, Prime, Target)

exp1_raw$device <- ifelse(exp1_raw$OS %in% c("Linux armv7l", "Linux armv8l"), "android", "computer")

# Filter valid participants
exp1_actual_participants <- filter(
  exp1_all_participants, 
  (PROLIFIC_PID %in% exp1_raw$participant) & 
  (nchar(PROLIFIC_PID) == 24) & 
  !(PROLIFIC_PID %in% c("5fa3b4abbcfd0b6c243758bc")) & 
  (`What is your age?` != 99) & 
  (`Response ID` != "R_sU4qJ6UCe9jRKs9")
)

# Filter accuracy >= 80% and full completion (480 trials)
exp1_accuracy_by_participant <- exp1_raw %>% 
  filter(participant %in% exp1_actual_participants$PROLIFIC_PID) %>% 
  group_by(source) %>% 
  summarise(acc = mean(corr == 1), N = n(), .groups = "drop")

exp1_participants_to_include <- exp1_accuracy_by_participant %>% 
  filter(N == 480 & acc >= .8)

# Factor levels, labels, and sum-to-zero contrasts
exp1_data_to_include <- exp1_raw %>% 
  filter(source %in% exp1_participants_to_include$source & participant %in% exp1_actual_participants$PROLIFIC_PID) %>% 
  mutate(
    StimulusType = factor(StimulusType, levels = c("NW", "WORD"), labels = c("Nonword", "Word")), 
    Condition = factor(Condition, levels = c("ID", "UN"), labels = c("Identical", "Unrelated")), 
    PrimeDuration = factor(PrimeDuration, levels = c(33, 50), labels = c("33 ms", "50 ms")), 
    rt = rt # RT in seconds
  )

contrasts(exp1_data_to_include$Condition) <- c(-.5, .5)
contrasts(exp1_data_to_include$PrimeDuration) <- c(-.5, .5)

# Save to single qs2 file
output_path <- "Angele_et_al_2022/exp1_data.qs2"
qs_save(exp1_data_to_include, output_path)
cat(sprintf("Successfully saved %d trials to %s (%0.2f KB)\n", 
            nrow(exp1_data_to_include), output_path, file.size(output_path) / 1024))
