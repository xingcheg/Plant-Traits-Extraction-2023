# this .R use Keras to train our CNN model for 
# foreground- and background-plant classification

library(keras)
source("model_train/plant_cropping_labeling.R")

N <- length(Y)
shuffle_idx <- sample(N)
Y <- Y[shuffle_idx]
X <- X[shuffle_idx,,,]

Y <- to_categorical(Y, 2)
#l1 <- 16
#l2 <- 16

#####Define and Train Network#####
mlp<-keras_model_sequential()
mlp %>%
  layer_conv_2d(filters = 32, kernel_size = c(3,3), input_shape = c(2*l1+1, 2*l2+1, 3),
                activation = "relu", data_format="channels_last", padding = "same") %>%
  layer_conv_2d(filters = 32, kernel_size = c(3,3), 
                activation = "relu", padding = "same") %>%
  layer_max_pooling_2d(pool_size=c(2,2)) %>% 
  layer_conv_2d(filters = 64, kernel_size = c(3,3), 
                activation = "relu", padding = "same") %>%
  layer_conv_2d(filters = 64, kernel_size = c(3,3), 
               activation = "relu", padding = "same") %>%
  layer_max_pooling_2d(pool_size=c(2,2)) %>% 
  #flatten the input  
  layer_flatten() %>% 
  layer_dropout(0.3) %>%
  layer_dense(units=128,activation="relu") %>%
  layer_dropout(0.3) %>%
  layer_dense(units=2,activation="sigmoid")

summary(mlp)  #can use to view a description of the network before training

mlp %>% compile(
  loss = 'binary_crossentropy',
  optimizer = optimizer_adam(0.001),
  metrics = c('accuracy')
)                                      #define optimization algorithm and loss function


history <- mlp %>% fit(
  X, Y, 
  epochs = 100, batch_size = 1000, 
  validation_split = 0.05,
  callbacks = list(callback_model_checkpoint(filepath = "SS_CNN.hdf5", 
                                             save_best_only = TRUE,
                                             monitor = "val_acc",
                                             mode = "max"))
)                                     



