# Load necessary libraries
library(gtools)   # for permutations
library(dplyr)
library(ggplot2)
library(gridExtra)
library(kableExtra)
library(IRdisplay)
library(rootSolve)

# Load your data
team_estim <- read.csv("TeamEstim.csv", stringsAsFactors = FALSE)
