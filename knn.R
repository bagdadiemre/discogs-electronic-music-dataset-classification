install.packages(c("e1071", "cvms", "caret", "ggplot2", "lattice", "pROC", "dplyr"))
library(ggplot2)
library(lattice)
library(e1071)
library(cvms)
library(caret)
library(pROC)
library(dplyr)

data<-read.csv("/Users/borapapila/Desktop/ML_Term_Project/discogs_electronic.csv")

delete_column <- c("artist", "title", "label", "country", "styles", "format", "genre")
data <- data %>% select(-one_of(delete_column))

data <- data[data$num_ratings != 0, ]
data <- data[!is.na(data$num_ratings), ]
data <- data[!is.na(data$lowest_price), ]
data <- data[data$lowest_price != 0, ]
data <- data[!is.na(data$median_price), ]
data <- data[data$median_price != 0, ]
data <- data[!is.na(data$highest_price), ]
data <- data[data$highest_price != 0, ]

data$release_date <- substr(data$release_date, 1, 4)

data$release_date <- as.numeric(as.character(data$release_date))
data$average_rating <- as.numeric(as.character(data$average_rating))
data$lowest_price <- as.numeric(sub("\\$", "", data$lowest_price))
data$median_price <- as.numeric(sub("\\$", "", data$median_price))
data$highest_price <- as.numeric(sub("\\$", "", data$highest_price))
data$lowest_price <- as.numeric(sub("\\$", "", data$lowest_price))
data$median_price <- as.numeric(sub("\\$", "", data$median_price))
data$highest_price <- as.numeric(sub("\\$", "", data$highest_price))


data$num_interestReal <- data$have + data$want
data$num_interest <- ifelse(data$num_interestReal < 200, 0, 1)

delete_column <- c("have", "want", "num_interestReal")
data <- data %>% select(-one_of(delete_column))

sayi_0 <- table(data$num_interest)[1]
sayi_1 <- table(data$num_interest)[2]


columns <- c("num_ratings", "average_rating", "lowest_price", "median_price", "highest_price")

for (col in columns) {
  # Check for missing values
  if (any(is.na(data[[col]]))) {
    # Handle missing values (you can choose to impute or remove rows with missing values)
    data <- data[!is.na(data[[col]]), ]
  }
  
  q1 <- quantile(data[[col]], 0.25, na.rm = TRUE)
  q3 <- quantile(data[[col]], 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr
  
  # Identify and remove outliers
  outliers <- which(data[[col]] < lower_bound | data[[col]] > upper_bound)
  data <- data[-outliers, ]
}

cols_to_normalize <- c('num_ratings', 'average_rating', 'lowest_price', 'median_price', 'highest_price')

normalize_minmax <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}

data[cols_to_normalize] <- lapply(data[cols_to_normalize], normalize_minmax)

set.seed(123)
train_indices <- createDataPartition(data$num_interest, p = 0.8, list = FALSE)
train_data <- data[train_indices, ]
test_data <- data[-train_indices, ]

train_data[cols_to_normalize] <- lapply(train_data[cols_to_normalize], normalize_minmax)
test_data[cols_to_normalize] <- lapply(test_data[cols_to_normalize], normalize_minmax)

data$num_interest <- as.factor(data$num_interest)
train_data$num_interest <- as.factor(train_data$num_interest)
test_data$num_interest <- as.factor(test_data$num_interest)

ctrl <- trainControl(method = "cv", number = 5)

knn_model <- train(
  num_interest ~ .,
  data = train_data,
  method = "knn",
  trControl = ctrl,
  tuneGrid = expand.grid(k = seq(1, 20, by = 1))
)

optimal_k <- knn_model$bestTune$k

predictions_knn <- predict(knn_model, newdata = test_data)

conf_matrix_knn <- confusionMatrix(predictions_knn, test_data$num_interest)

roc_curve <- roc(test_data$num_interest, as.numeric(predictions_knn))
auc_value <- auc(roc_curve)

cat("Optimal k for kNN:", optimal_k, "\n")
cat("kNN Confusion Matrix:\n", conf_matrix_knn$table, "\n")
cat("kNN Accuracy:", conf_matrix_knn$overall["Accuracy"], "\n")
cat("kNN Precision:", conf_matrix_knn$byClass["Pos Pred Value"], "\n")
cat("kNN Recall (Sensitivity):", conf_matrix_knn$byClass["Sensitivity"], "\n")
cat("kNN F1 Score:", conf_matrix_knn$byClass["F1"], "\n")
cat("kNN AUC:", auc_value, "\n")



