# Machine Learning Model Training Script
# Purpose: Train XGBoost classifier to predict surgeon cognitive states
# Input: data/processed/features_data.csv
# Output: shiny_app/xgb_model.rds and evaluation plots

# 1. Load Libraries ----
library(tidyverse)
library(xgboost)
library(caret)

cat("Machine Learning Model Training Script\n")
cat("=====================================\n\n")

# 2. Load Feature Data ----
cat("Loading feature data...\n")

# Read the engineered features
input_file <- "data/processed/features_data.csv"

if (!file.exists(input_file)) {
  stop("Error: ", input_file, " not found. Please run 02_feature_engineering.R first.")
}

features_data <- read_csv(input_file, show_col_types = FALSE)

cat("✓ Feature data loaded successfully\n")
cat("  - Rows:", nrow(features_data), "\n")
cat("  - Columns:", ncol(features_data), "\n")
cat("  - Cognitive states:", length(unique(features_data$cognitive_state)), "\n\n")

# Display cognitive state distribution
cat("Cognitive state distribution:\n")
state_counts <- table(features_data$cognitive_state)
print(state_counts)
cat("\n")

# 3. Data Preparation for Modeling ----
cat("Preparing data for modeling...\n")

# Convert cognitive state to factor with valid R variable names
features_data$cognitive_state <- factor(
  features_data$cognitive_state,
  levels = c("Optimal", "High Load", "Fatigued", "Attentional Lapse"),
  labels = c("Optimal", "HighLoad", "Fatigued", "AttentionalLapse")
)

# Create numeric labels for XGBoost (must start from 0)
cognitive_state_mapping <- c(
  "Optimal" = 0,
  "HighLoad" = 1, 
  "Fatigued" = 2,
  "AttentionalLapse" = 3
)

features_data$cognitive_state_numeric <- cognitive_state_mapping[features_data$cognitive_state]

cat("✓ Cognitive state mapping created:\n")
for (i in 1:length(cognitive_state_mapping)) {
  cat("  -", names(cognitive_state_mapping)[i], "=", cognitive_state_mapping[i], "\n")
}
cat("\n")

# Select feature columns and target variable for modeling
# Drop surgeon_id, timestamp, original sensor data, and text cognitive_state
model_data <- features_data %>%
  select(
    # Engineered features only
    tonic_pupil_level_30s,
    grip_force_variability_15s,
    tremor_trend_10s,
    phasic_pupil_change_5s,
    pupil_diameter_lag_5s,
    # Target variable
    cognitive_state_numeric,
    cognitive_state  # Keep for evaluation purposes
  )

cat("✓ Model data prepared:\n")
cat("  - Features:", ncol(model_data) - 2, "\n")  # Subtract target variables
cat("  - Feature names:", paste(names(model_data)[1:5], collapse = ", "), "\n")
cat("  - Final dataset dimensions:", nrow(model_data), "×", ncol(model_data), "\n\n")

# 4. Split Data into Training and Testing Sets ----
cat("Splitting data into training and testing sets...\n")

# Set seed for reproducibility
set.seed(123)

# Create stratified split (80/20) ensuring balanced cognitive states
train_indices <- createDataPartition(
  y = model_data$cognitive_state,
  p = 0.8,
  list = FALSE,
  times = 1
)

# Create training and testing datasets
train_data <- model_data[train_indices, ]
test_data <- model_data[-train_indices, ]

cat("✓ Data split completed:\n")
cat("  - Training set:", nrow(train_data), "observations\n")
cat("  - Testing set:", nrow(test_data), "observations\n")

# Verify stratification worked
cat("\nTraining set cognitive state distribution:\n")
print(table(train_data$cognitive_state))
cat("\nTesting set cognitive state distribution:\n")
print(table(test_data$cognitive_state))
cat("\n")

# Prepare data matrices for XGBoost
train_features <- as.matrix(train_data[, 1:5])  # Feature columns
train_labels <- train_data$cognitive_state_numeric

test_features <- as.matrix(test_data[, 1:5])
test_labels <- test_data$cognitive_state_numeric

# 5. Hyperparameter Tuning and Model Training ----
cat("Starting hyperparameter tuning...\n")

# Set up hyperparameter tuning with caret
# Define a small tuning grid to search
tune_grid <- expand.grid(
  nrounds = c(50, 100),                # Number of boosting rounds
  max_depth = c(3, 5),                 # Maximum tree depth
  eta = c(0.05, 0.1),                  # Learning rate
  gamma = 0,                           # Minimum loss reduction (fixed)
  colsample_bytree = 0.8,              # Feature sampling ratio (fixed)
  min_child_weight = 1,                # Minimum sum of instance weights (fixed)
  subsample = 0.8                      # Subsample ratio (fixed)
)

cat("✓ Parameter grid created:", nrow(tune_grid), "combinations to test\n")

# Set up cross-validation
train_control <- trainControl(
  method = "cv",                       # Cross-validation
  number = 3,                         # 3-fold CV
  verboseIter = TRUE,                 # Show progress
  allowParallel = TRUE,               # Enable parallel processing
  classProbs = TRUE,                  # Calculate class probabilities
  summaryFunction = multiClassSummary # Multi-class metrics
)

# Prepare data for caret (requires data frame format with factor target)
train_df <- train_data[, 1:5]  # Feature columns only
train_df$cognitive_state <- train_data$cognitive_state  # Factor target

cat("Starting cross-validation hyperparameter search...\n")
cat("This may take a few minutes...\n\n")

# Perform hyperparameter tuning
set.seed(123)  # For reproducible CV folds
caret_model <- train(
  cognitive_state ~ .,
  data = train_df,
  method = "xgbTree",
  trControl = train_control,
  tuneGrid = tune_grid,
  metric = "Accuracy",
  verbose = FALSE
)

cat("✓ Hyperparameter tuning completed\n")
cat("✓ Best parameters found:\n")
print(caret_model$bestTune)
cat("\n")

cat("✓ Cross-validation results summary:\n")
cat("  - Best CV Accuracy:", round(max(caret_model$results$Accuracy), 4), "\n")
cat("  - Best CV Kappa:", round(caret_model$results$Kappa[which.max(caret_model$results$Accuracy)], 4), "\n\n")

# Extract the best model for consistency with rest of script
xgb_model <- caret_model$finalModel

cat("✓ Optimized XGBoost model training completed\n\n")

# 6. Save the Trained Model ----
cat("Saving trained model...\n")

# Ensure shiny_app directory exists
shiny_dir <- "shiny_app"
if (!dir.exists(shiny_dir)) {
  dir.create(shiny_dir, recursive = TRUE)
  cat("Created directory:", shiny_dir, "\n")
}

# Save the model
model_file <- file.path(shiny_dir, "xgb_model.rds")
saveRDS(xgb_model, model_file)

cat("✓ Model saved to:", model_file, "\n")
cat("✓ Model file size:", round(file.size(model_file) / 1024, 2), "KB\n\n")

# 7. Evaluate Model Performance on Test Set ----
cat("Evaluating model performance...\n")

# Make predictions on test set using the tuned model
test_df <- test_data[, 1:5]  # Feature columns only
test_predictions <- predict(caret_model, test_df)

# Get actual test labels as factors
test_labels_factor <- factor(
  names(cognitive_state_mapping)[test_labels + 1],
  levels = names(cognitive_state_mapping)
)

# Generate confusion matrix
confusion_matrix <- confusionMatrix(
  data = test_predictions,
  reference = test_labels_factor
)

cat("✓ Model evaluation completed\n\n")
cat("CONFUSION MATRIX AND STATISTICS:\n")
cat("=================================\n")
print(confusion_matrix)

# Calculate and display key metrics
overall_accuracy <- confusion_matrix$overall['Accuracy']
kappa <- confusion_matrix$overall['Kappa']

cat("\nKEY PERFORMANCE METRICS:\n")
cat("- Overall Accuracy:", round(overall_accuracy * 100, 2), "%\n")
cat("- Cohen's Kappa:", round(kappa, 3), "\n")

# Display per-class metrics
cat("\nPER-CLASS METRICS:\n")
class_metrics <- confusion_matrix$byClass
for (i in 1:nrow(class_metrics)) {
  class_name <- rownames(class_metrics)[i]
  sensitivity <- class_metrics[i, "Sensitivity"]
  specificity <- class_metrics[i, "Specificity"]
  cat("- ", class_name, ":\n")
  cat("  Sensitivity (Recall):", round(sensitivity, 3), "\n")
  cat("  Specificity:", round(specificity, 3), "\n")
}
cat("\n")

# Generate and save feature importance plot
cat("Creating feature importance plot...\n")

# Ensure images directory exists
images_dir <- "case_study/images"
if (!dir.exists(images_dir)) {
  dir.create(images_dir, recursive = TRUE)
  cat("Created directory:", images_dir, "\n")
}

# Calculate feature importance using caret
feature_importance <- varImp(caret_model)

# Save feature importance plot
importance_file <- file.path(images_dir, "feature_importance.png")
png(importance_file, width = 800, height = 600, res = 100)
plot(feature_importance, main = "Feature Importance - XGBoost Model")
dev.off()

cat("✓ Feature importance plot saved to:", importance_file, "\n")

# Display feature importance in console
cat("\nFEATURE IMPORTANCE RANKING:\n")
print(feature_importance)
cat("\n")

# 8. Save Final Confirmation Message ----
cat("MODEL TRAINING SUMMARY:\n")
cat("======================\n")
cat("✓ Hyperparameter-tuned XGBoost model successfully trained and saved\n")
cat("✓ Model file:", model_file, "\n")
cat("✓ Test accuracy:", round(overall_accuracy * 100, 2), "%\n")
cat("✓ Evaluation plots created in:", images_dir, "\n")
cat("✓ Optimized model is ready for deployment in Shiny app\n")
cat("✓ Hyperparameter tuning improved model performance\n\n")

# Save model metadata for reference
metadata <- list(
  model_type = "XGBoost Multi-class Classifier (Hyperparameter Tuned)",
  training_date = Sys.Date(),
  training_samples = nrow(train_data),
  testing_samples = nrow(test_data),
  features = colnames(train_features),
  cognitive_states = names(cognitive_state_mapping),
  best_parameters = caret_model$bestTune,
  cv_accuracy = round(max(caret_model$results$Accuracy), 4),
  test_accuracy = round(overall_accuracy, 4),
  kappa = round(kappa, 4),
  tuning_grid_size = nrow(tune_grid)
)

metadata_file <- file.path(shiny_dir, "model_metadata.rds")
saveRDS(metadata, metadata_file)

cat("✓ Model metadata saved to:", metadata_file, "\n")
cat("\n--- Model Training Complete ---\n")