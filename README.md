# Premier League Season Simulator

This project simulates full English Premier League (EPL) seasons using a **Poisson-based hierarchical goal model**. It applies **Monte Carlo methods** to evaluate how team strength, random variation, and marginal changes in strategy translate into league outcomes and economic value. The simulation framework estimates **expected values**, **variances**, and **counterfactual impacts** under different assumptions of performance and fortune.

## Motivation

The English Premier League allocates hundreds of millions of pounds annually based on final table positions. While team quality plays a large role, randomness and scheduling quirks can significantly affect outcomes. This project uses statistical modeling to quantify these dynamics: how much success is driven by strength, how much by luck, and where small changes can yield disproportionate returns.

At the heart of the simulation is a **probabilistic match outcome engine** built on team-specific attack and defense strengths. Match results are generated stochastically across full seasons, with outcomes translated into revenue via **placement-based prize mapping**.

## Data Sources and Preparation

We use match-level data from the **2023–24 and 2024–25 English Premier League seasons** to estimate team-specific scoring tendencies.

Each match record includes:
- Match date
- Home team and away team
- Final score (home and away goals)

These data are used to fit **Poisson goal models** that estimate:
- **Attack strength (alpha)**: how often a team scores
- **Defense strength (beta)**: how often a team concedes

### Processing Workflow:
1. Standardize team names and match structures
2. Generate home/away goal records
3. Fit a Poisson regression model for goals scored as:
   ```math
   \text{Goals}_{ij} \sim \text{Poisson}(\lambda_{ij}), \quad \lambda_{ij} = \exp(\alpha_i - \beta_j)
   ```
4. Estimate all team-specific parameters via maximum likelihood

**Output**:  
Each team receives an `alpha` and `beta` used in simulation.

**Interpretation**:  
This method captures latent team quality and relative performance based on actual matches. Using two full seasons improves estimation stability and reduces noise from short-term anomalies.

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
  \text{Goals}_A \sim \text{Poisson}(\lambda_A), \quad \lambda_A = \exp(\alpha_A - \beta_B)
  ```
- Simulate goals scored by Team B:
  ```math
  \text{Goals}_B \sim \text{Poisson}(\lambda_B), \quad \lambda_B = \exp(\alpha_B - \beta_A)
  ```

Where:
- $\( \alpha_i \):$ attack strength of team $\( i \)$
- $\( \beta_i \):$ defense strength of team $\( i \)$
- $\( \lambda \):$ expected goals for each side, always positive due to exponential transformation

We simulate all **380 matches** of the season using this method.

### Season Simulation Loop

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
6. **Repeat for thousands of seasons** to build full distributions for each team

```r
monte.carlo.sim<-function(fun,fun.arg,nSims=10000){
    # this line just runs fun(arguments in fun.arg list) so if fun.arg=(x,y,z) do.call(fun,fun.arg) runs fun(x,y,z)
    rep1<- do.call(fun,fun.arg) 
    # Set the dimensions for the output matrix
    nc<-length(rep1)
    lbl<-names(rep1)
    outputMatrix <- matrix(1,nrow=nSims, ncol=nc)
    outputMatrix[1, ]<-rep1 # write the sim to the first line
    for (rep in 2:nSims) { # for each of the remaining sims, add them in
        outputMatrix[rep, ] <- do.call(fun,fun.arg)}
    df<-data.frame(outputMatrix) # convert it to a data frame
    names(df)<-lbl  # get the names from the simulation output lbl
    return(df) # return the data frame as the output}

# Simulate 1000 seasons
season_sims <- monte.carlo.sim(
  fun = simulate_season,
  fun.arg = list(alphaList = alphaList, deltaList = deltaList, team_names = team_names),
  nSims = 1000
)
```

**Interpretation**:  
This process creates thousands of alternate versions of the same season under probabilistic laws. The resulting distributions show not only what's likely—but what’s possible.



## Expected Performance: Estimating Revenue, Not Rank

We report the **expected revenue** (in GBP millions) for each team across all simulations.

- Output:  
  - Mean revenue per team  
  - Confidence intervals or standard errors

**Interpretation**:  
Expected revenue better reflects a team’s value under uncertainty than rank alone. It captures how often a team reaches high-paying vs. low-paying outcomes—making it a better metric for strategic decision-making.

---

## Variability in Outcomes: Measuring Risk and Volatility

We analyze the **revenue distribution** for each team to understand how fragile or stable their expected outcomes are.

- Metrics:  
  - Standard deviation, IQR  
  - Full distribution visualizations (e.g., boxplots, violin plots)

**Interpretation**:  
Some teams show wide revenue swings due to their proximity to important thresholds (Top 4, relegation). These teams are more vulnerable to randomness and may benefit from risk-mitigation strategies (e.g., squad depth, consistent play styles).



## Value of Luck: Simulating a Marginal Win

To assess the financial value of good fortune, we simulate the impact of converting **one random loss into a win**.

- Method:  
  - Identify one random loss per team per season simulation  
  - flip the score (convert to a win (+3 points)) 
  - Rerank season, recompute revenue  
  - Compare to baseline revenue

- Output:  
  - Average revenue change due to a single "lucky" win

**Interpretation**:  
This simulates the **financial value of luck**. For teams hovering around key thresholds, a single result can swing tens of millions. It helps identify where outcomes are most sensitive—and where clubs should aim to reduce randomness.



## Investment Leverage: Offense vs. Defense Improvements

We simulate two hypothetical improvements for each team:

1. A **10% increase in expected goals scored**
2. A **10% reduction in expected goals conceded**

These changes are implemented by **solving for parameter shifts** in the log-scale of the Poisson model.

### Method: Root-Solving for Shifted Parameters

Given the scoring model:

```math
\lambda = \exp(\alpha - \beta)
```

We solve for:
- $\( \Delta \alpha = \log(1.10) \)$ to increase goals scored by 10%
- $\( \Delta \beta = \log(1.10) \)$ to decrease goals conceded by 10%

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

### Output:

- Change in expected revenue under each intervention

**Interpretation**:  
This allows teams to compare the **financial ROI** of improving attack vs. defense. Some clubs benefit more from scoring upgrades; others from tightening defense. This data-driven approach helps guide investment priorities, recruitment, and tactical decisions.



## Key Takeaways

- Premier League outcomes translate into steep, nonlinear revenue differences.
- Expected rank is uniform; **expected revenue is not**—and it's what truly matters.
- **Randomness is financially meaningful**: small shifts in match results can change revenue by millions.
- Teams differ not just in strength, but in volatility. Simulation helps quantify both.
- A simulation-based approach provides a **strategic planning tool**: to evaluate improvement paths, quantify luck, and allocate resources more effectively.


