# ⚽ Premier League Season Simulator

This project simulates full English Premier League (EPL) seasons using a **Poisson-based goal model**. It uses **Monte Carlo simulation** to explore how expected team strength, randomness, and strategy affect league performance and financial outcomes. The aim is to quantify expected value, variance, and marginal effects of both chance and investment.

---

## 📊 Motivation

This project uses simulation to explore how match-level probabilities scale up to full-season outcomes. At its core is a **probabilistic model of scoring** built from team-specific attack and defense strengths. This generates synthetic seasons, where each run mimics the entire EPL calendar. Final rankings are mapped to real-world **financial outcomes**, allowing for economic analysis of team performance.

### 💷 Revenue Mapping by League Position

Each team's simulated final league position is mapped to a **revenue effect (in GBP millions)** relative to finishing 17th (considered the baseline). These values approximate earnings from TV rights, prize money, and exposure.

| Position | Revenue Effect |
|----------|----------------|
| 1        | +149.6         |
| 2        | +145.9         |
| 3        | +142.1         |
| 4        | +138.4         |
| 5        | +73.7          |
| 6        | +70.0          |
| 7        | +55.2          |
| 8        | +33.5          |
| 9        | +29.8          |
| 10       | +26.0          |
| 11       | +22.3          |
| 12       | +18.6          |
| 13       | +14.9          |
| 14       | +11.2          |
| 15       | +7.5           |
| 16       | +3.7           |
| 17       | 0              |
| 18       | −88.7          |
| 19       | −92.5          |
| 20       | −96.2          |

---

## 🧠 How the Model Works

Each season simulation follows a multi-step process:

### 1. **Goal Generation**
Each match between Team A and Team B generates scores as:

```math
\text{Goals}_A \sim \text{Poisson}(\lambda_A), \quad \lambda_A = \exp(\text{attack}_A - \text{defense}_B)
```

```math
\text{Goals}_B \sim \text{Poisson}(\lambda_B), \quad \lambda_B = \exp(\text{attack}_B - \text{defense}_A)
```

Where:
\begin{itemize}
  \item \(\text{attack}_i\) is the attacking strength of team \(i\),
  \item \(\text{defense}_i\) is the defensive strength of team \(i\),
  \item \(\lambda_A, \lambda_B\) are the expected number of goals for teams A and B,
  \item and \(\exp(\cdot)\) ensures \(\lambda > 0\).
\end{itemize}

These `attack` and `defense` parameters are team-specific and estimated externally.

### 2. **Match Outcome Assignment**
For each of the **380 matches** (home and away between all 20 teams):
- Simulate the scoreline
- Assign points: 3 for a win, 1 for a draw, 0 for a loss
- Track goals for, goals against

### 3. **League Table Construction**
At the end of the season:
- Aggregate each team's:
  - Total points
  - Goal difference
  - Goals scored
- Apply tie-breaking rules:
  1. Points
  2. Goal difference
  3. Goals scored
  4. Random draw

### 4. **Revenue Assignment**
Each team’s rank is translated into a revenue figure using the table above.

### 5. **Monte Carlo Aggregation**
This entire process is repeated over **thousands of simulated seasons**. For each team, we compute:
- Expected rank
- Expected revenue
- Standard deviation and quantiles
- Marginal effects (e.g., of a lucky win or performance improvement)

---

## 🔍 Motivation Questions

### 1. 📈 Expected Performance: Who are the best and worst teams?

Across thousands of seasons, we aggregate each team’s **mean final position**, giving us a ranking based purely on model expectations.

**Output:**
- Bar plot of expected position with confidence intervals  
**Insight:** Which teams are objectively strongest under the model?

---

### 2. 📉 Variability in Outcomes: Which teams are most volatile?

Not all teams have consistent results — some are highly variable due to randomness or placement near competitive thresholds (e.g., Top 4, relegation).

**Outputs:**
- Standard deviation and IQR of final rank and revenue
- Distribution plots (boxplots, violin plots) showing outcome spread

**Insight:**
- Which teams face high risk?
- Where is season outcome most unpredictable?

---

### 3. 🍀 Value of Luck: Who benefits most from a "lucky win"?

We rerun simulations where, for each team, **one randomly selected loss is converted to a win**, holding everything else constant.

**Process:**
- Recompute points, standings, and revenue for that one change
- Repeat across simulations
- Take the **average revenue gain per team**

**Output:**
- Bar chart showing marginal value of a lucky win

**Insight:**  
Which teams sit just on the edge of a financial cliff?  
Where does small luck have outsized value?

---

### 4. ⚔️ Offense vs. Defense: Where should teams invest?

Each team is independently modified in two scenarios:
1. Increase expected goals scored by 10%
2. Decrease expected goals conceded by 10%

**Process:**
- Modify the relevant Poisson rate
- Rerun thousands of seasons
- Compute the revenue change from baseline

**Output:**
- Side-by-side bars for offensive and defensive improvement per team

**Insight:**  
Should a team spend to score more or concede less?  
Which lever gives the best ROI?

---

## ✅ Key Takeaways

- The league's **economic structure** amplifies small differences in performance.
- **Randomness** can yield major swings — one match can move millions.
- Monte Carlo simulation reveals not just **who’s good**, but who’s **risky**.
- Teams should tailor strategy: for some, **scoring more** pays; for others, **defending better** is more valuable.
