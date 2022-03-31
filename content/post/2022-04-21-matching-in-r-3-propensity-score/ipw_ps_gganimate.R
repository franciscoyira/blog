# Loading packages and data
library(tidyverse)
library(gganimate)
# requires: install.packages("gifski")
library(twang)

data(lalonde)

# Propensity score estimation with {twang}
ps_lalonde_gbm <-  ps(
  treat ~ age + educ + black + hispan + nodegree +
    married + re74 + re75,
  data = lalonde,
  n.trees = 10000,
  interaction.depth = 2,
  shrinkage = 0.01,
  estimand = "ATT",
  stop.method = "ks.max",
  n.minobsinnode = 10,
  n.keep = 1,
  n.grid = 25,
  ks.exact = NULL,
  verbose = FALSE
)

# Data manipulation stage
lalonde_w_ps <- lalonde %>% 
  dplyr::select(treat, outcome = re78) %>% 
  mutate(prop_score = ps_lalonde_gbm$ps[[1]])

lalonde_for_gganimate <-
  bind_rows(
    lalonde_w_ps %>%
      mutate(
        weighting = "ATT",
        weights = ifelse(treat == 1,
                         yes = 1,
                         no = 1 * prop_score / (1 - prop_score))
      ),
    lalonde_w_ps %>%
      mutate(weighting = "No weighting (observational)",
             weights = 1)
  ) %>% 
  mutate(treat = factor(treat,
                        levels = c(0,1),
                        labels = c("Untreated", "Treated")),
         weighting = factor(weighting,
                            levels = c("No weighting (observational)",
                                       "ATT")))

# Second dataset: means
lalonde_means_gganimate <- lalonde_for_gganimate %>% 
  group_by(treat, weighting) %>% 
  summarise(mean_outcome = weighted.mean(outcome, weights),
            .groups = "drop")


# Third dataset with the estimated ATT
sdo <- function(df) {
  outcome_treat <- df %>% 
    filter(treat == "Treated") %>% 
    pull(mean_outcome)
  
  outcome_untreated <- df %>% 
    filter(treat == "Untreated") %>% 
    pull(mean_outcome)
  
  outcome_treat - outcome_untreated
}

lalonde_treat_effect <- lalonde_means_gganimate %>%
  group_nest(weighting) %>%
  mutate(sdo = map_dbl(data, sdo)) %>% 
  dplyr::select(-data)

# ggplot code
iptw_plot <- ggplot(lalonde_for_gganimate) +
  geom_point(aes(prop_score, outcome, color = treat,
                 size = weights, alpha = weights)) +
  geom_hline(data = lalonde_means_gganimate,
             aes(yintercept = mean_outcome, color = treat),
             size = 1.3,
             show.legend = FALSE) +
  geom_text(data = lalonde_treat_effect,
            aes(label = str_c("Difference Treated minus Control:", round(sdo, 2))),
            x =0.5,
            y =19500) +
  scale_alpha_continuous(range = c(0.2, 0.9),
                         guide = NULL) +
  ylim(c(0, 20000)) +
  labs(title = 'Weighting: {closest_state}',
       subtitle = "Horizontal line is group average",
       x = 'Propensity score',
       y = 'Outcome',
       color = 'Treatment status',
       size = 'Weight') +
  # gganimate code
  transition_states(
    weighting,
    transition_length = 2,
    state_length = 1
  ) +
  enter_fade() + 
  exit_shrink() +
  ease_aes('sine-in-out')

# Exporting as GIF
animation_obj <- animate(iptw_plot, nframes = 150, fps=35,
        height = 400, width = 600, res=110,
        renderer = gifski_renderer())

anim_save("iptw.gif", animation_obj)
