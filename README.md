# Premier League Season Simulator 

This project simulates full English Premier League (EPL) seasons using a **Poisson-based hierarchical goal model**. It applies **Monte Carlo methods** to evaluate how team strength, random variation, and marginal changes in strategy translate into league outcomes and economic value. The simulation framework estimates **expected values**, **variances**, and **counterfactual impacts** under different assumptions of performance and fortune.

## Motivation

The English Premier League allocates hundreds of millions of pounds annually based on final table positions. While team quality plays a large role, randomness and scheduling quirks can significantly affect outcomes. This project uses statistical modeling to quantify these dynamics: how much success is driven by strength, how much by luck, and where small changes can yield disproportionate returns.

At the heart of the simulation is a **probabilistic match outcome engine** built on team-specific attack and defense strengths. Match results are generated stochastically across full seasons, with outcomes translated into revenue via **placement-based prize mapping**.

## Data Processing & Statistical Modeling

This project estimates team-specific attacking and defensive abilities in the English Premier League using historical match outcomes. We model the number of goals each team scores using a Poisson log-linear model, with parameters estimated via maximum likelihood.

### Data Sources

We use match-level data from the 2021-22, 2022-23 and 2023–24 EPL seasons. Each record includes:

- Home and away team names  
- Match date  
- Final score (home goals, away goals)

The data is preprocessed into a long format, with one row per team per match (i.e., each match yields two observations — one for home team goals, one for away).

```r
data2023.24 <- read.csv('https://www.football-data.co.uk/mmz4281/2324/E0.csv')
data2022.23 <- read.csv('https://www.football-data.co.uk/mmz4281/2223/E0.csv')
```



### Statistical Model

We assume that the number of goals team *i* scores against team *j* follows a Poisson distribution:

```math
y_{ij} \sim \text{Poisson}(\lambda_{ij}), \quad \lambda_{ij} = \exp(\alpha_i - \delta_j)
```

Where:

- $\alpha_i$: Latent attack strength of team *i*  
- $\delta_j$: Latent defense weakness of team *j*  
- $\lambda_{ij}$: Expected goals scored by team *i* vs. *j*

Each match contributes two observations:

- Home team goals: $\lambda_{\text{home}} = \exp(\alpha_{\text{home}} - \delta_{\text{away}})$  
- Away team goals: $\lambda_{\text{away}} = \exp(\alpha_{\text{away}} - \delta_{\text{home}})$


### Parameter Estimation

We estimate the parameters $\alpha$ and $\delta$ via maximum likelihood, maximizing the log-likelihood function:

```math
\mathcal{L} = \sum_{m=1}^M \left[ y_m \log(\lambda_m) - \lambda_m - \log(y_m!) \right]
```

Where:

- $y_m$: Observed goal count  
- $\lambda_m = \exp(\alpha_i - \delta_j)$: Modeled rate  
- $M$: Total number of team-match observations

The negative log-likelihood is minimized using `scipy.optimize.minimize` (e.g., L-BFGS-B).

```r
out<-optim(theta0,likelihood.function,control= list(fnscale=-1), method="BFGS"  )
```



### Identifiability and Normalization

The model is overparameterized: adding a constant to all $\alpha$ values and subtracting it from all $\delta$ values leaves predictions unchanged. To ensure identifiability, we impose the constraint:

$$
\sum_i \alpha_i = 0
$$

This centers team attack strengths relative to a league-average baseline.

```r
alphaOut[20] <-  -1*sum( alphaOut[1:19] ) #sum to zero constraint
deltaOut[20] <-  -1* sum( deltaOut[1:19] )
```

**Interpretation**

- $\alpha_i > 0$: Team *i* scores more than average (strong offense)  
- $\delta_j < 0$: Team *j* concedes fewer goals than average (strong defense)

These parameters provide a quantitative summary of team quality, inferred from observed match outcomes.

## Revenue Mapping by League Position

Each team’s simulated final league position is mapped to a revenue effect in GBP millions, centered relative to 17th place (the baseline). These estimates approximate broadcasting, merit, and exposure-based earnings.

```r
# Hard code value of earnings and position

revenue_by_position <- data.frame(
  position = 1:20,
  revenue_million_gbp = c(
    149.6, 145.9, 142.1, 138.4, 73.7, 70.0, 55.2, 33.5, 29.8, 26.0,
    22.3, 18.6, 14.9, 11.2, 7.5, 3.7, 0, -88.7, -92.5, -96.2))
```

**Interpretation**:  
The financial structure of the EPL is nonlinear. A shift from 17th to 18th (relegation) costs ~£89 million, while a Top 4 finish is worth ~£140 million more than just avoiding relegation. As such, financial outcomes vary far more than ranks do—and it's this revenue distribution we model and analyze.

## Modeling and Simulation Procedure

### Monte Carlo Match Simulation

We simulate each EPL season using **Monte Carlo methods**, where match outcomes are generated stochastically based on Poisson-distributed goals.

For each match between Team A and Team B:
- Simulate goals scored by Team A:
  ```math
  \text{Goals}_A \sim \text{Poisson}(\lambda_A), \quad \lambda_A = \exp(\alpha_A - \delta_B)
  ```
- Simulate goals scored by Team B:
  ```math
  \text{Goals}_B \sim \text{Poisson}(\lambda_B), \quad \lambda_B = \exp(\alpha_B - \delta_A)
  ```

Where:
- $\( \alpha_i \):$ attack strength of team $\( i \)$
- $\( \delta_i \):$ defense strength of team $\( i \)$
- $\( \lambda \):$ expected goals for each side, always positive due to exponential transformation

We simulate all **380 matches** of the season using this method for 1000 seasons.

### Season Simulation Function to Apply Monte Carlo

Each simulated season proceeds as follows:

1. **Generate all Possible Matches**

```
# Simulate each match
ScoresMatrix <- matrix(nrow = nrow(allMatches), ncol = 4)
for (ii in 1:nrow(allMatches)) {
  ScoresMatrix[ii, 1:2] <- allMatches[ii, ]
  ScoresMatrix[ii, 3:4] <- draw.score(allMatches[ii, "home"], allMatches[ii, "away"])}
colnames(ScoresMatrix) <- c("home.team", "away.team", "home.score", "away.score")
```
No Repeats

+ 20*38 = 760, but do not recount because teams play each other

+ 760/2 = **380** total matches (with no repeats)


2. **Generate match Goals** using Poisson sampling

```r
# Function to simulate a single match
draw.score <- function(team1, team2) {
  c(
    rpois(1, exp(alphaList[team1] - deltaList[team2])),
    rpois(1, exp(alphaList[team2] - deltaList[team1])))}
```

3. **Assign points** based on outcomes (3 for win, 1 for draw, 0 for loss)
4. **Construct the league table** using total points, goal difference, and goals scored
5. **Map final ranks to revenue** using the revenue table
6. **Repeat for a thousand seasons** to build full distributions for each team

```r
# Simulate 1000 seasons
season_sims <- monte.carlo.sim(
  fun = simulate_season,
  fun.arg = list(alphaList = alphaList, deltaList = deltaList, team_names = team_names),
  nSims = 1000)
```


This process creates thousands of alternate versions of the same season under probabilistic laws. The resulting simulations show what’s possible, and the aggregation of many simulations shows what is likely.



## Expected Performance: Estimating Revenue

We report the **expected revenue** (in GBP millions) for each team across all simulations.

<div align="center">
  <img src="https://github.com/RoryQo/premier-league-revenue-simulation-model/blob/main/Figures/avg_revenue_plot.png?raw=true" width="500px">
</div>


Expected revenue better reflects a team’s value under uncertainty than rank alone. It captures how often a team reaches high-paying vs. low-paying outcomes—making it a better metric for strategic decision-making.


## Variability in Outcomes: Measuring Risk and Volatility

We analyze the **revenue distribution** for each team to understand how fragile or stable their expected outcomes are.

<div align="center">
  <img src="https://github.com/RoryQo/premier-league-revenue-simulation-model/blob/main/Figures/sd.png?raw=true" width="400px" style="margin-right: 20px;">
  <img src="https://github.com/RoryQo/premier-league-revenue-simulation-model/blob/main/Figures/CI.png?raw=true" width="400px">
</div>

  
  
Some teams show wide revenue swings due to their proximity to important thresholds such as Top 4 qualification or relegation. These teams are more exposed to randomness and may benefit from risk-mitigation strategies (e.g., increasing squad depth, stabilizing tactics, or reducing match-to-match variance).

The **left plot** shows the **standard deviation of revenue** across all simulated seasons — this represents the actual volatility in outcomes that a team might experience. In contrast, the **right plot** shows **confidence intervals around the average revenue**, indicating the precision of our estimate of each team’s expected revenue.

Importantly, the CI bars on the right do **not** reflect the full spread of revenue outcomes — they are much narrower and only quantify **uncertainty in the mean**, not variability in individual season results. The SD plot on the left captures that total variability directly.



## Value of Luck: Simulating a Marginal Win

To assess the financial value of good fortune, we simulate the impact of converting **one random loss into a win**. 20 teams × 1,000 simulations = 20,000 “flip scenarios” and 1000 baseline simulated seasons

- Method:  
  - Identify one random loss per team per simulationed season  
  - flip the score (convert to a win (+3 points)) 
  - Rerank season, recompute revenue  
  - Compare to baseline revenue

- Output:  
  - Average revenue change due to a single "lucky" win

 
<div align="center">
  <img src="https://github.com/RoryQo/premier-league-revenue-simulation-model/blob/main/Figures/lucky.png?raw=true" width="500px">
</div>


This analysis quantifies the **marginal financial value of luck**. For teams near key thresholds (e.g., 4th vs. 5th, or 17th vs. 18th), a single lucky result can be worth **tens of millions of pounds**. Teams with steep revenue gradients around their most likely finish (e.g., high mid-table or relegation zone) tend to benefit most from small improvements.

There’s also a **strategic angle** to the lucky win: there is a chance that the win occurs **against a direct rival in the table** — a team close in points and position. Flipping that match not only gains 3 points but **potentially removes 3 points** from a close competitor, increasing the likelihood of leapfrogging them in the standings.

Given 380 matches in the season and 19 possible opponents per team, the probability of your lucky win being **against a direct competitor** (e.g., within 1–2 places in the table) is non-trivial. Roughly:
- Each team plays 38 matches
- Suppose 1-2 of those are realistically close rivals over the season
- Then the chance that your lucky win occurs against one of those is about **5%-20%** (depending on total wins and losses, and win/loss against rivals)

This makes the expected revenue gain from a flipped result not just a reflection of your own improvement — but potentially a **double swing** in revenue if it knocks a nearby team down a position.


## Investment Leverage: Offense vs. Defense Improvements

We simulate two hypothetical improvements for each team:

1. A **10% increase in expected goals scored**
2. A **10% reduction in expected goals conceded**

To simulate marginal improvements in team performance, we implement a function that computes the required increase in a team’s attack strength parameter, `αᵢ`, to produce a **10% increase in average expected goals** across opponents.


### Method: Root-Solving for Shifted Parameters

Under a Poisson goals model, the expected number of goals scored by team $i$ against opponent $j$ is modeled as:

$$
\mathbb{E}[Y_{ij}] = \exp(\alpha_i - \delta_j)
$$

We solve for a shifted value $\alpha_i^*$ such that the average expected goals increases by 10%. Formally, this requires solving:

$$
\frac{1}{N} \sum_{j \ne i} \exp(\alpha_i^* - \delta_j) = 1.1 \times \left( \frac{1}{N} \sum_{j \ne i} \exp(\alpha_i - \delta_j) \right)
$$

This is implemented as a nonlinear root-finding problem in $\alpha_i^*$, keeping the opponent defense parameters $\delta_j$ fixed.



This required shift is **team-specific**. The magnitude of $\alpha_i^* - \alpha_i$ depends on the distribution of opponent defensive strengths $\delta_j$ faced by team $i$. Because expected goals are computed via a nonlinear exponential transformation, the same 10% increase in mean goals requires a different adjustment to $\alpha_i$ for each team.

This transformation enables fair and interpretable simulations of performance gains, aligning latent skill improvements to a consistent increase in expected output while accounting for the surrounding competitive environment.

These shifts are applied **per team** using a **custom root-solving function**.

```r
# Define the alphaShift function
alphaShift <- function(team) {
    # Ensure alphaIn is numeric
    alphaIn <- as.numeric(team_estim[team, "alpha"])
    # Ensure otherTeams are correct
    otherTeams <- setdiff(rownames(team_estim), team)
    
    # Define the function to solve for the 10% increase (vectorized)
    fn <- function(x) {
        # We are comparing two values - return the difference as a vector
        result <- mean(exp(x - as.numeric(team_estim[otherTeams, "delta"]))) - 
                 1.1 * mean(exp(alphaIn - as.numeric(team_estim[otherTeams, "delta"])))
        
        # Return the result as a vector with the expected structure
        return(c(result))}
    
    # Use multiroot to solve for the value of alphaIn that increases the parameter by 10%
    sol <- multiroot(fn, alphaIn, rtol = 1e-12, atol = 1e-8)
    return(sol$root)}
```

### Revenue Delta Calculation

For each team, we run three simulation sets:

1. **Baseline:** simulate a thousand of seasons with original $\( \alpha \)$, $\( \delta \)$ (already done)
2. **Attack Boost:** apply $\( \Delta \alpha_i  \)$, re-simulate
3. **Defense Boost:** apply $\( \Delta \delta_i \)$, re-simulate

For each intervention, we compute the **change in expected revenue** relative to the baseline:

```math
\Delta \text{Revenue}_{\text{attack}} = \mathbb{E}[R_{\text{attack}}] - \mathbb{E}[R_{\text{baseline}}]
```
```math
\Delta \text{Revenue}_{\text{defense}} = \mathbb{E}[R_{\text{defense}}] - \mathbb{E}[R_{\text{baseline}}]
```

Where $\( R \)$ represents simulated total revenue over a season.

+ 1,000 baseline simulations and 500 simulations for each of 20 teams with the alpha boost, a total of 21000 simulated full seasons (attack and defense)

### Output:

- Average the thousand revenue changes for each team

<div align="center">
  <img src="https://github.com/RoryQo/premier-league-revenue-simulation-model/blob/main/Figures/scatter.png?raw=true" width="500px">
</div>


 
This allows teams to compare the **financial ROI** of improving attack vs. defense. Some clubs benefit more from scoring upgrades; others from tightening defense. This data-driven approach helps guide investment priorities, recruitment, and tactical decisions.

In the plot, each point represents a team:
- Teams **above the diagonal line** benefit more from **defensive improvements** (reducing goals conceded).
- Teams **below the line** benefit more from **offensive upgrades** (increasing goals scored).
- Teams **on or near the line** show roughly **equal financial returns** from both types of improvements.



## Key Takeaways

- Premier League outcomes translate into steep, nonlinear revenue differences.
- Expected rank is uniform; **expected revenue is not**—and it's what truly matters.
- **Randomness is financially meaningful**: small shifts in match results can change revenue by millions.
- Teams differ not just in strength, but in volatility. Simulation helps quantify both.
- A simulation-based approach provides a **strategic planning tool**: to evaluate improvement paths, quantify luck, and allocate resources more effectively.


