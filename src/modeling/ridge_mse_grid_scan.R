# Anticancer drug combination project
# Original source file: MSEss.R
# Purpose: Scan test-set MSE across a Ridge lambda grid after a model object has already been created in the workspace.
# Note: Run this script from the repository root so relative paths resolve correctly.

MSEss <- rep(0,201)
for (i in 1:200){
  S = 10 ^ ((-1)+((i-1)/199)*(-4.8-(-1)))
  ridges.pred = predict (ridge.mod, s = S, newx = x_test_ridge)
  ridges.MSE =  mean((ridges.pred - y_test)^2)
  MSEss[i] <- ridges.MSE
}
qr.pred = predict (ridge.mod, s = 0, newx = x_test_ridge)
qr.MSE =  mean((qr.pred - y_test)^2)
MSEss[201] <- qr.MSE

qr.coef=predict (ridge.mod, type="coefficients", s=0)[1:15, ]

qr.MSE <- MSEss[201]