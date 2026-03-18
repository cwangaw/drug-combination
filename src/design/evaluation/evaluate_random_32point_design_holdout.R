# Anticancer drug combination project
# Original source file: Design_random.R
# Purpose: Evaluate a random 32-point design on held-out combinations.
# Note: Run this script from the repository root so relative paths resolve correctly.

myData <- read.csv("data/raw/drug_viability_data.csv")
library(glmnet)
library(RSNNS)
library(randomForest)
library(NeuralNetTools)

x <- as.matrix(myData[2:5])
y <- as.vector(as.matrix(myData[6]))

#1. Quadratic Regression

#Normalization

xnorm <- normalizeData(x, type = "0_1")
#xnorm <- x

#Input Matrix

InputForQR <- xnorm

for (i in 1:4) {
  for (j in 1:i){
    InputForQR <- cbind(InputForQR, xnorm[,i]*xnorm[,j])
  }
}

colnames(InputForQR) <- c("V", "M", "E", "D", "VV", "VM", "MM","VE", "ME", "EE", "VD", "MD", "ED", "DD")

#InputForQR <- normalizeData(InputForQR, type = "0_1")

#Regression Model

qm = lm(y ~ InputForQR)
summary(qm)


#2. Random Forest

#DataProcessing


set.seed(1)
NewOrder <- sample(256)
DataForQR <- data.frame(InputForQR, y)
DataForRF <- DataForQR[NewOrder, ]

x_train <- DataForRF[1:32,1:14]
y_train <- DataForRF[1:32 ,15]
x_test <- DataForRF[33:256, 1:14]
y_test <- DataForRF[33:256, 15]


#Model

RF.mod <- randomForest(x = x_train, y = y_train, importance = TRUE)
print(RF.mod)
round(importance(RF.mod), 2)

randfore.pred <- predict(RF.mod, x_test)
randfore.MSE =  mean((randfore.pred - y_test)^2)

#3. Lasso 

x_train_lasso <- as.matrix(x_train)

grid = 10 ^ seq(-1,-4.3,length = 200)
lasso.mod =glmnet (x_train_lasso, y_train, alpha=1, lambda=grid)
lasso.result <- coef(lasso.mod)

#Lasso with 8-fold cv

set.seed(2) 

cv.out =cv.glmnet (x_train_lasso, y_train, alpha = 1, nfold = 8)
plot(cv.out)
#bestlam =cv.out$lambda.min
bestlam=10 ^ ((-1)+((118-1)/199)*(-4.3-(-1)))
sparselam = cv.out$lambda.1se
sparselam = sparselam - cv.out$lambda.min + bestlam

#Prediction with bestlam

x_test_lasso <- as.matrix(x_test)
lasso.pred = predict (lasso.mod, s = bestlam, newx = x_test_lasso)
lasso.MSE =  mean((lasso.pred - y_test)^2)
lasso.coef=predict (lasso.mod, type="coefficients", s=bestlam)[1:15, ]

#Prediction with sparselam

lasso.pred2 = predict (lasso.mod, s = bestlam+sparselam-bestlam, newx = x_test_lasso)
lasso.MSE2 =  mean((lasso.pred2 - y_test)^2)
lasso.coef2 =predict (lasso.mod, type="coefficients", s=bestlam+sparselam-bestlam)[1:15, ]

#Plotting

plot(lasso.mod, xvar = c("lambda"), label = TRUE, xlim = c(-10, -2))
points(x = seq(from = log(bestlam), to = log(bestlam), length.out = 100), 
       y = seq(from = -0.4, to = 0.2, length.out =100), pch = ".")
points(x = seq(from = log(bestlam+sparselam-bestlam), to = log(bestlam+sparselam-bestlam), length.out = 100), 
       y = seq(from = -0.4, to = 0.2, length.out =100), pch = ".")

plot(lasso.mod, xvar = c("norm"), label = TRUE)


#4. Ridge 

x_train_ridge <- as.matrix(x_train)

grid = c(10 ^ seq(-1,-4.8,length = 200),0)
ridge.mod =glmnet (x_train_ridge, y_train, alpha=0, lambda=grid)
ridge.result <- coef(ridge.mod)

#Ridge with 8-fold cv

set.seed(3) 

cv2.out =cv.glmnet (x_train_ridge, y_train, alpha = 0, nfold = 8)
plot(cv2.out)
#bestlam2 =cv2.out$lambda.min
bestlam2 = 10 ^ ((-1)+((33-1)/199)*(-4.8-(-1)))

#Prediction with bestlam

x_test_ridge <- as.matrix(x_test)
ridge.pred = predict (ridge.mod, s = bestlam2, newx = x_test_ridge)
ridge.MSE =  mean((ridge.pred - y_test)^2)
ridge.coef=predict (ridge.mod, type="coefficients", s=bestlam2)[1:15, ]

#5. Multi-Linear Perceptron

set.seed(4)
mlp.mod <- mlp(x = x_train, y = y_train, size = 16)
mlp.pred <- predict(mlp.mod, x_test)
mlp.MSE <- mean((mlp.pred - y_test)^2)

garson(mlp.mod, y_train)

#1'.Quadratic Regression-Redo

#x_qr <- x_train_lasso
#qr = lm(y_train ~ x_qr)
#qr.pred <- predict(qr,  x_qr = x_test)
#qr.MSE <- mean((qr.pred - y_test)^2)

