# Install required R packages for this repository.
required_packages <- c("glmnet", "RSNNS", "randomForest", "NeuralNetTools")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}
