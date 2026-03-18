# Anticancer drug combination project
# Original source file: MSEs.R
# Purpose: Scan test-set MSE across a Lasso lambda grid after a model object has already been created in the workspace.
# Note: Run this script from the repository root so relative paths resolve correctly.

MSEs <- rep(0,200)
for (i in 1:200){
  S = 10 ^ ((-1)+((i-1)/199)*(-4.3-(-1)))
  lassos.pred = predict (lasso.mod, s = S, newx = x_test_lasso)
  lassos.MSE =  mean((lassos.pred - y_test)^2)
  MSEs[i] <- lassos.MSE
  }