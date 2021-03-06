# parameters for simulation

# Ashcroft et al. infectivity profile
# https://smw.ch/article/doi/smw.2020.20336
infect_shape = 97.18750 
infect_rate  =  3.71875
infect_shift = 25.62500

# Lauer et al. incubation period
# https://www.acpjournals.org/doi/10.7326/M20-0504
rriskDistributions::get.lnorm.par(q = c(5.1, 11.5),
                                  p = c(0.5, 0.975),
                                  plot = F,
                                  show.output = F) %>%
  as.list %>%
  set_names(., c("mu_inc", "sigma_inc")) -> inc_parms

pathogen <- list(
  symptomatic = 
    # review paper Byrne et al. (2020) https://doi.org/10.1101/2020.04.25.20079889
    # define T1 as infection to beginning of presymptomatic infectious period
    append(
      # https://www.acpjournals.org/doi/10.7326/M20-0504
      inc_parms,
      
      # Li et al https://www.nejm.org/doi/full/10.1056/nejmoa2001316
      # variance calculated by inverting confidence interval
      list(mu_inf    = 9.1,
           sigma_inf = 14.7)),
  
  asymptomatic = 
    append(
      # https://www.acpjournals.org/doi/10.7326/M20-0504
      inc_parms,
      # https://doi.org/10.1101/2020.04.25.20079889
      list(
        mu_inf    =  6,
        sigma_inf = 12))) %>%
  map(~data.frame(.x), .id = "type")

# https://www.medrxiv.org/content/10.1101/2020.04.25.20079103v3
asymp_fraction <- rriskDistributions::get.beta.par(
  q = c(0.24,  0.38),
  p = c(0.025, 0.975), 
  show.output = F, plot = F) %>%
  as.list

waning_none <- function(x){
  waning_points(x, X = 0, Y = 1)
}

adhere_10 <- function(x){
  waning_points(x, X = 0, Y = 0.1)
}
adhere_20 <- function(x){
  waning_points(x, X = 0, Y = 0.2)
}
adhere_30 <- function(x){
  waning_points(x, X = 0, Y = 0.3)
}
adhere_40 <- function(x){
  waning_points(x, X = 0, Y = 0.4)
}
adhere_50 <- function(x){
  waning_points(x, X = 0, Y = 0.5)
}
adhere_60 <- function(x){
  waning_points(x, X = 0, Y = 0.6)
}
adhere_70 <- function(x){
  waning_points(x, X = 0, Y = 0.7)
}
adhere_80 <- function(x){
  waning_points(x, X = 0, Y = 0.8)
}
adhere_90 <- function(x){
  waning_points(x, X = 0, Y = 0.9)
}
adhere_100 <- function(x){
  waning_points(x, X = 0, Y = 1)
}

waning_constant <- function(x){
  waning_points(x, X = 0, Y = 0.75)
}

# waning_drop <- function(x){
#   waning_piecewise_linear(x, 0.75, 0.25, 7, 14)
# }

# waning_linear <- function(x){
#   waning_piecewise_linear(x, ymax = 0.75, .16, 0, 8.3)
# }

# waning_canada_community <- function(x){
#   waning_points(x, X = c(0, 30), Y = c(1, 0.541), log = T)
# }

waning_canada_total <- function(x){
  waning_points(x, X = c(0, 30), Y = c(1, 0.158), log = T)
}

smith_uk <- function(x){
  waning_points(x, X = 0, Y = 0.109)
}

input <- 
  tibble(pathogen = "SARS-CoV-2") %>%
  bind_cols(., list(
    `none` = 
      crossing(screening         = FALSE,
               first_test_delay  = NA,
               quar_dur = seq(0,14,by=1)), 
    `one` = 
      crossing(screening         = TRUE,
               first_test_delay  = NA,
               quar_dur = seq(0,14,by=1)),
    `two` = 
      crossing(screening         = TRUE,
               first_test_delay  = 0,
               quar_dur = seq(0,14,by=1))) %>% 
      bind_rows(.id = "stringency")) %>% 
  crossing(post_symptom_window =  10,
           results_delay       =  2,
           index_test_delay    =  c(1, 2, 3),  # time to entering quarantine
           delay_scaling       =  c(1, 0.5),
           waning              =c("adhere_10",
                                  "adhere_20",
                                  "adhere_30",
                                  "adhere_40",
                                  "adhere_50",
                                  "adhere_60",
                                  "adhere_70",
                                  "adhere_80",
                                  "adhere_90",
                                  "adhere_100")
           #                      = c("waning_none",
           #                         "waning_constant",
           #                         "waning_canada_total",
           #                         "smith_uk")
           
           ) %>%
  mutate(scenario=row_number()) %>% 
  #calculate time until release from exposure for each scenario
  mutate(time_since_exp=ifelse(stringency=="none",
                               yes=quar_dur,
                               no=quar_dur + results_delay * delay_scaling))