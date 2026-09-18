\appendix
\section*{Appendix: R Code}
\begin{lstlisting}[style=Rstyle]
# loading libraries
library(plm)
library(sandwich)
library(lmtest)
library(stargazer)
library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)

# SIMPLE OLS 
# OLS market cap -  gender diversity
lm1 <- lm(lnmktcap ~ genderdiversity, data = pgfc2008) 
summary(lm1)
# OLS short-term debt and gender diversity
lm2 <- lm(shortdebtcentrage ~ genderdiversity, data = pgfc2008) 
summary(lm2)
# OLS market cap - skill ratio 
lm3 <- lm(lnmktcap ~ skillratio, data = pgfc2008) 
summary(lm3) 
# OLS short-term debt - skill ratio 
lm4 <- lm(shortdebtcentrage ~ skillratio, data = pgfc2008) 
summary(lm4)

# EXTENDED OLS
# sector is turned as factor variable
pgfc2008$sector <- factor(pgfc2008$sector)
# regressions
lm5  <- lm(lnmktcap ~  genderdiversity + age + sector , data = pgfc2008)
summary(lm5)
lm6 <- lm(shortdebtcentrage ~ genderdiversity  + age + sector  , data = pgfc2008)
summary(lm6)
lm7 <- lm(lnmktcap ~  skillratio + age + sector  , data = pgfc2008)
summary(lm7)
lm8 <- lm(shortdebtcentrage~  skillratio + age + sector  , data = pgfc2008)
summary(lm8)
# joint variables of interest
lm9 <- lm(lnmktcap ~ genderdiversity + skillratio + age + sector   , data = pgfc2008)
summary(lm9)
lm10 <- lm(shortdebtcentrage~  genderdiversity + skillratio +  age + sector , data = pgfc2008)
summary(lm10)

# dataset summary statistics
pgfc2008_clean <- subset(pgfc2008, select = -c(high_genderdiv, high_shortdebt, year_bin, dummy1, dummy2))
summary(pgfc2008_clean)
# distribution checks 
# log market cap
# Histogram + density overlay
ggplot(pgfc2008, aes(x = lnmktcap)) +
  geom_histogram(aes(y = ..density..), 
                 bins = 30, fill = "lightblue", color = "white") +
  geom_density(color = "darkblue", lwd = 1) +
  labs(title = "Distribution of Log Market Capitalization",
       x = "ln(market cap)", y = "Density") +
  theme_classic()
# centered-short term debt
# Histogram + density overlay
ggplot(pgfc2008, aes(x = shortdebtcentrage)) +
  geom_histogram(aes(y = ..density..),
                 bins = 30, fill = "lightblue", color = "white") +
  geom_density(color = "darkblue", lwd = 1) +
  labs(title = "Distribution of Centered Short-Term Debt",
       x = "Centered short-term debt", y = "Density") +
  theme_classic()
# gender diversity distribution
ggplot(pgfc2008, aes(x = genderdiversity)) +
  geom_histogram(fill = "lightblue", color = "white") +
  labs(title = "Distribution of gender diversity",
       x = "Share of women on the board") +
  theme_classic()

# DENSITY plot skill ratio
ggplot(pgfc2008, aes(x = skillratio)) +
  geom_density(fill="lightblue", alpha=0.6) +
  labs(title="Density of Skill Ratio",
       x="Share of skilled employees",
       y="Density") +
  theme_classic()

# BOXPLOT market capitalization by sector
ggplot(pgfc2008, aes(x = factor(sector), y = lnmktcap)) +
  geom_boxplot() +
  labs(
    title = "Distribution of log market capitalization by sector",
    x = "Sector",
    y = "Log market capitalization"
  ) +
  theme_classic()
# BOXPLOT centered short-term debt by sector
ggplot(pgfc2008, aes(x = factor(sector), y = shortdebtcentrage)) +
  geom_boxplot() +
  labs(
    title = "Distribution of centered short-term debt by sector",
    x = "Sector",
    y = "Centered short-term debt"
  ) +
  theme_classic()

# ONE WAY FIXED EFFECT MODEL
# log market cap + controls
fe_mkt <- plm(lnmktcap ~ genderdiversity + skillratio + age, 
              data  = pgfc2008, index =c("id", "year"), model = "within")
# short term debt centrage + controls
fe_std <- plm(shortdebtcentrage ~ genderdiversity + skillratio + age,
              data  = pgfc2008, index =c("id", "year"), model = "within")
# adding cluster-robust SE (at firm level)
robust_mkt <- vcovHC(fe_mkt, type = "HC1", cluster = "group")
robust_std <- vcovHC(fe_std, type = "HC1", cluster = "group")
se_mkt <- sqrt(diag(robust_mkt))
se_std <- sqrt(diag(robust_std))
# coefficient table
coeftest(fe_mkt, vcov = robust_mkt)
coeftest(fe_std, vcov = robust_std)

#   TWO WAYS FIXED EFFECT MODEL
# Log market cap with firm + year FE
fe_mkt_2w <- plm(lnmktcap ~ genderdiversity + skillratio + factor(year),
                 data = pgfc2008, index = c("id", "year"), model = "within")
# Short-term debt with firm + year FE
fe_std_2w <- plm( shortdebtcentrage ~ genderdiversity + skillratio + factor(year), data  = pgfc2008, index = c("id", "year"),
                  model = "within")
# Robust SE (clustered at firm level)
robust_mkt_2w <- vcovHC(fe_mkt_2w, type = "HC1", cluster = "group")
robust_std_2w <- vcovHC(fe_std_2w, type = "HC1", cluster = "group")
se_mkt_2w <- sqrt(diag(robust_mkt_2w))
se_std_2w <- sqrt(diag(robust_std_2w))
# Coefficient table: 
coeftest(fe_mkt_2w, vcov = robust_mkt_2w)
coeftest(fe_std_2w, vcov = robust_std_2w)

# DISTRIBUTION OF WITHIN-FIRM CHANGES: skill ratio
# changes in skill ratio from 2006 o 2007
skill_wide <- pgfc2008 %>% # Make wide format
  select(id, year, skillratio) %>%
  filter(year %in% c(2006, 2007)) %>%
  pivot_wider(
    names_from  = year,
    values_from = skillratio,
    names_prefix = "skill_"
  ) %>%
  filter(!is.na(skill_2006), !is.na(skill_2007))
# Compute the change
skill_diff <- skill_wide %>%
  mutate(delta_skill = skill_2007 - skill_2006)
# Plot histogram of the change
ggplot(skill_diff, aes(x = delta_skill)) +
  geom_histogram(binwidth = 0.01, fill="lightblue", color="white") +
  labs(
    title = "Distribution of within-firm changes in skill ratio",
    subtitle = "(2006–2007)",
    x = "Change in skill ratio (2007 - 2006)",
    y = "Number of firms"
  ) +
  theme_classic()

# DISTRIBUTION OF WITHIN-FIRM CHANGES: genderdiversity
# changes in gender diversity from 2006 to 2007
gender_wide <- pgfc2008 %>% 
  select(id, year, genderdiversity) %>%
  filter(year %in% c(2006, 2007)) %>%
  pivot_wider(
    names_from  = year,
    values_from = genderdiversity,
    names_prefix = "gender_"
  )
gender_diff <- gender_wide %>%
  mutate(delta_gender = gender_2007 - gender_2006)
ggplot(gender_diff, aes(x = delta_gender)) +
  geom_histogram(binwidth = 0.02, color = "white", fill ="lightblue") +
  labs(
    title = "Distribution of within-firm changes in gender diversity",
    x = "Change in gender diversity (2007 - 2006)",
    y = "Number of firms"
  ) +
  theme_classic()


# RANDOM FIXED EFFECTS
class(pgfc2008$sector ) # making sure sector is a factor
# log market cap - RE
re_mkt <- plm(lnmktcap ~ genderdiversity + skillratio + age + sector, 
              data  = pgfc2008, index =c("id", "year"), model = "random")
# short termd debt - RE
re_std <- plm(shortdebtcentrage ~ genderdiversity + skillratio + age + sector,
              data  = pgfc2008, index =c("id", "year"), model = "random")
# cluster robust standard errors 
robust_re_mkt <- vcovHC(re_mkt, type = "HC1", cluster = "group")
robust_re_std <- vcovHC(re_std, type = "HC1", cluster = "group")
se_re_mkt     <- sqrt(diag(robust_re_mkt))
se_re_std     <- sqrt(diag(robust_re_std))
# coefficient table
coeftest(re_mkt, vcov = robust_re_mkt)
coeftest(re_std, vcov = robust_re_std)

# Hausman tests: FE vs RE
hausman_mkt <- phtest(fe_mkt, re_mkt)
hausman_std <- phtest(fe_std, re_std)
hausman_mkt
hausman_std

# TESTING HETEROGENOUS EFFECTS through interaction terms
pgfc2008$base_emp <- ave(pgfc2008$emp, pgfc2008$id,
                         FUN = function(x) mean(x, na.rm = TRUE)) #baseline firm size (proxied by employees)
pgfc2008$base_gender <- ave(pgfc2008$genderdiversity, pgfc2008$id,
                            FUN = function(x) mean(x, na.rm = TRUE)) #baseline gender diversity 
pgfc2008$year2007 <- as.numeric(pgfc2008$year == 2007) # 2007 year dummy

# LOG MARKET CAPITALIZATION
# testing if the effect of gender diversity and skill ratio varies with firm size:
fe_inter_size_mkt <- plm(
  lnmktcap ~ genderdiversity*base_emp + skillratio*base_emp + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_size_mkt,
         vcov = vcovHC(fe_inter_size_mkt, type = "HC1", cluster = "group"))
# testing if the effect differs between firms with already more women on board:
fe_inter_gdiv_mkt <- plm(
  lnmktcap ~ genderdiversity*base_gender + skillratio + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_gdiv_mkt,
         vcov = vcovHC(fe_inter_gdiv_mkt, type = "HC1", cluster = "group"))
# heterogeneity by age:
fe_inter_age_mkt <- plm(
  lnmktcap ~ genderdiversity*age + skillratio + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_age_mkt,
         vcov = vcovHC(fe_inter_age_mkt, type = "HC1", cluster = "group"))
# testing if the effect changed with the macroeconomic shock: interaction between
# skillratio and genderdiversity and the 2007 dummy.
fe_inter_year_mkt <- plm(
  lnmktcap ~ genderdiversity*year2007 + skillratio*year2007 + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_year_mkt,
         vcov = vcovHC(fe_inter_year_mkt, type = "HC1", cluster = "group"))

# SHORT-TERM DEBT
# testing if the effect of gender diversity and skill ratio varies with firm size:
fe_inter_size_debt <- plm(
  shortdebtcentrage ~ genderdiversity*base_emp + skillratio*base_emp + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_size_debt,
         vcov = vcovHC(fe_inter_size_debt, type = "HC1", cluster = "group"))
# testing if the effect differs between firms with already more women on board:
fe_inter_gdiv_debt <- plm(
  shortdebtcentrage ~ genderdiversity*base_gender + skillratio + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_gdiv_debt,
         vcov = vcovHC(fe_inter_gdiv_debt, type = "HC1", cluster = "group"))
# heterogeneity by age: 
fe_inter_age_debt <- plm(
  shortdebtcentrage ~ genderdiversity*age + skillratio + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_age_debt,
         vcov = vcovHC(fe_inter_age_debt, type = "HC1", cluster = "group"))
# testing if the effect changed with the macroeconomic shock: interaction between
# skillratio and genderdiversity and the 2007 dummy.
fe_inter_year_debt <- plm(
  shortdebtcentrage ~ genderdiversity*year2007 + skillratio*year2007 + age,
  data = pgfc2008,
  index = c("id","year"),
  model = "within")
coeftest(fe_inter_year_debt,
         vcov = vcovHC(fe_inter_year_debt, type = "HC1", cluster = "group"))




