# Anticancer drug combination project
# Original source file: Design_32_2.R
# Purpose: Search for a 32-point space-filling design via permutation-based centered L2-discrepancy minimization (coded levels).
# Note: Run this script from the repository root so relative paths resolve correctly.

myData <- read.csv("data/raw/drug_viability_data.csv")
library(RSNNS)
x <- as.matrix(myData[2:5])
x <- normalizeData(x, type = "0_1")
#Dc <- x[c(1,22,43,64,71,84,109,122,140,159,162,181,206,217,232,243),]

#Level Permutation
y=x
for (i in 1:256){
    for (j in  1:4){ 
        if (x[i,j] == 0.125) y[i,j]=1/3
        if (x[i,j] == 0.250) y[i,j]=2/3
        if (x[i,j] == 1) y[i,j]=3/3
    }
}

Dc_I <- y[c(1,16,22,27,38,43,49,64,66,79,85,92,101,108,114,127,
            136,137,147,158,163,174,184,185,199,202,212,221,228,237,247,250),]
Dc <- Dc_I

ExRow <- function(x, y, j, p){
    #    if (j == 1) s = c(0, 6.25, 12.50, 50.00)
    #    if (j == 2) s = c(0, 5, 10, 40)
    #    if (j == 3) s = c(0, 12.5, 25, 100)
    #    if (j == 4) s = c(0, 9.375, 18.750, 75.000)
    s = c(0,1/3,2/3,3/3)
    for (i in 1:32){
        if (x[i,j] == 0) y[i,j] = s[p[1]]
        if (x[i,j] == 1/3) y[i,j] = s[p[2]]
        if (x[i,j] == 2/3) y[i,j] = s[p[3]]
        if (x[i,j] == 3/3) y[i,j] = s[p[4]]
    }
    return(y)
}

# Calculate the aquared centered L_2-discrepancy

CDSqr <- function(x){
    CDS = 0
    for (i in 1:32){
        for (j in 1:32){
            A = 1
            for (k in 1:4){
                A = A*(1+0.5*abs(x[i,k]-0.5)+0.5*abs(x[j,k]-0.5)-0.5*abs(x[i,k]-x[j,k]))
            }
            CDS = CDS + (1/(32*32))*A
        }
    }
    for (i in 1:32){
        B = 1
        for (k in 1:4){
            B = B*(1+0.5*abs(x[i,k]-0.5)-0.5*((x[i,k]-0.5)^2))
        }
        CDS = CDS - (2/32)*B
    }
    CDS = CDS + (13/12)^4
    return(CDS)
}

#Initial parameters

Dc_min = Dc
Dc_0 = Dc
delta_0 = (1/10)*CDSqr(Dc)
u_0 = 0.1

#Permutation Group

Perm <- matrix(c(1,2,3,4,1,2,4,3,1,3,2,4,1,3,4,2,1,4,2,3,1,4,3,2,
                 2,1,3,4,2,1,4,3,2,3,1,4,2,3,4,1,2,4,1,3,2,4,3,1,
                 3,1,2,4,3,1,4,2,3,2,1,4,3,2,4,1,3,4,1,2,3,4,2,1,
                 4,1,2,3,4,1,3,2,4,2,1,3,4,2,3,1,4,3,1,2,4,3,2,1), 
               nrow = 24, ncol = 4, byrow = TRUE)

#Algorithm 1


for (p_1 in 1:24){
    for (p_2 in 1:24){
        for (p_3 in 1:24){
            for (p_4 in 1:24){
                D_new <- ExRow(Dc_I, Dc, 1, Perm[p_1,])
                D_new <- ExRow(Dc_I, D_new, 2, Perm[p_2,])
                D_new <- ExRow(Dc_I, D_new, 3, Perm[p_3,])
                D_new <- ExRow(Dc_I, D_new, 4, Perm[p_4,])
                delta = CDSqr(D_new)-CDSqr(Dc_0)
                u = runif(1)
                if (delta < 0 || (delta<delta_0 && u<u_0)){
                    Dc_0 = D_new
                }
                if (CDSqr(Dc_0)-CDSqr(Dc_min)<0){ 
                    Dc_min = Dc_0
                }
            }
        }
    }
}
