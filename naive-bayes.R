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

boxplot(data$num_ratings, main="Boxplot of Num_Ratings")
boxplot(data$lowest_price, main="Boxplot of Lowest Prices")
boxplot(data$median_price, main="Boxplot of Median Price")
boxplot(data$highest_price, main="Boxplot of Highest Price")
boxplot(data$average_rating, main="Boxplot of Average Ratings")

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

boxplot(data$num_ratings, main="Boxplot of Num_Ratings")
boxplot(data$lowest_price, main="Boxplot of Lowest Prices")
boxplot(data$median_price, main="Boxplot of Median Price")
boxplot(data$highest_price, main="Boxplot of Highest Price")
boxplot(data$average_rating, main="Boxplot of Average Ratings")

cols_to_normalize <- c('num_ratings', 'average_rating', 'lowest_price', 'median_price', 'highest_price')

normalize_minmax <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}

data[cols_to_normalize] <- lapply(data[cols_to_normalize], normalize_minmax)

features <- data[, c('num_ratings', 'average_rating', 'lowest_price', 'median_price', 'highest_price')]

# Create a data frame with the target variable
target <- data$num_interest

# Combine features and target into a single data frame
classification_data <- cbind(features, target)

data$num_interest <- as.factor(data$num_interest)

set.seed(123)
train_indices <- createDataPartition(data$num_interest, p = 0.7, list = FALSE)
train_data <- data[train_indices, ]
test_data <- data[-train_indices, ]

train_data[cols_to_normalize] <- lapply(train_data[cols_to_normalize], normalize_minmax)
test_data[cols_to_normalize] <- lapply(test_data[cols_to_normalize], normalize_minmax)

ctrl <- trainControl(method = "cv", number = 5)

naive_bayes_model <- train(
  num_interest ~ .,
  data = train_data,
  method = "naive_bayes",
  trControl = ctrl
)

predictions <- predict(naive_bayes_model, newdata = test_data)

predictions <- factor(predictions, levels = levels(test_data$num_interest))

conf_matrix <- confusionMatrix(predictions, test_data$num_interest)

precision <- conf_matrix$byClass["Pos Pred Value"]
recall <- conf_matrix$byClass["Sensitivity"]
f1_score <- 2 * (precision * recall) / (precision + recall)
auc <- roc(test_data$num_interest, as.numeric(predictions))$auc

print("Confusion Matrix:")
print(conf_matrix$table)
print(paste("Accuracy:", conf_matrix$overall["Accuracy"]))
print(paste("Precision:", precision))
print(paste("Recall (Sensitivity):", recall))
print(paste("F1 Score:", f1_score))
print(paste("AUC:", auc))



head(data)
View(data)
