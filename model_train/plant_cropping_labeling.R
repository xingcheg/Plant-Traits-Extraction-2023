# this .R file prepares CNN training data by cropping and labeling 
# background-removed images
setwd("/Users/apple/Desktop/SS-CNN")

set.seed(213213)

library(jpeg)
library(EBImage)

## read jpeg black and white image
readJPEG_bw  <- function(name) {
  out <- round( as.matrix(readJPEG(name)) )
  return( out )
}



## function that can create training data
create_training_sample <- function(img, seg, l1, l2, cut, N = 1000, save_combine = FALSE,
                                   save_label = FALSE, combine_path = NULL, label_path = NULL){
  
  R <- dim(seg)[1]
  C <- dim(seg)[2]
  R1 <- dim(img)[1]
  C1 <- dim(img)[2]
  if ((R!=R1) | (C!=C1)){
    img <- resize(img, R, C)
  }
  
  img1 <- img
  img1[,,1] <- img[,,1] * seg
  img1[,,2] <- img[,,2] * seg
  img1[,,3] <- img[,,3] * seg
  
  if (save_combine == TRUE){
    writeJPEG(img1, combine_path)
  }
  
  plant_ind <- which(seg[(l1+1):(R-l1), (l2+1):(C-l2)] == 1, arr.ind = TRUE)
  plant_ind[,1] <- plant_ind[,1] + l1
  plant_ind[,2] <- plant_ind[,2] + l2
  plant_ind_2 <- plant_ind[plant_ind[,1] <= cut, ]
  plant_ind_1 <- plant_ind[plant_ind[,1] > cut, ]
  
  plant_ind_train_1 <- plant_ind_1[sample(nrow(plant_ind_1), N), ]
  plant_ind_train_2 <- plant_ind_2[sample(nrow(plant_ind_2), N), ]
  
  if (save_label == TRUE){
    img3 <- array(0, c(R, C, 3))
    for (i in 1:nrow(plant_ind_1)){
      img3[plant_ind_1[i,1], plant_ind_1[i,2], 1] <- 1
    }
    for (i in 1:nrow(plant_ind_2)){
      img3[plant_ind_2[i,1], plant_ind_2[i,2], 3] <- 1
    }
    writeJPEG(img3, label_path)
  }
  
  X <- array(0, c(2*N, 2*l1+1, 2*l2+1, 3))
  
  
  for (i in 1:N){
    row1 <- plant_ind_train_1[i,1]
    col1 <- plant_ind_train_1[i,2]
    X[i, , , ] <- img1[ (row1-l1):(row1+l1), (col1-l2):(col1+l2),]
    row2 <- plant_ind_train_2[i,1]
    col2 <- plant_ind_train_2[i,2]
    X[i+N, , , ] <- img1[ (row2-l1):(row2+l1), (col2-l2):(col2+l2),]
  }
  return(list(X = X, Y = rep(c(0,1), each = N)))
}




l1 <- 16
l2 <- 16
#################################################
##        training data ( from photo 1)        ##
#################################################
img <- readJPEG("model_train/img/train_1.JPG")
seg <- readJPEG_bw("model_train/seg/train_1.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 340

Out1 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_1.JPG", 
                               label_path = "model_train/label/train_1.JPG")





#################################################
##        training data ( from photo 2)        ##
#################################################
img <- readJPEG("model_train/img/train_2.JPG")
seg <- readJPEG_bw("model_train/seg/train_2.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 410

Out2 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_2.JPG", 
                               label_path = "model_train/label/train_2.JPG")





#################################################
##        training data ( from photo 3)        ##
#################################################
img <- readJPEG("model_train/img/train_3.JPG")
seg <- readJPEG_bw("model_train/seg/train_3.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 420

Out3 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_3.JPG", 
                               label_path = "model_train/label/train_3.JPG")




#################################################
##        training data ( from photo 4)        ##
#################################################
img <- readJPEG("model_train/img/train_4.JPG")
seg <- readJPEG_bw("model_train/seg/train_4.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 350

Out4 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_4.JPG", 
                               label_path = "model_train/label/train_4.JPG")





#################################################
##        training data ( from photo 5)        ##
#################################################
img <- readJPEG("model_train/img/train_5.JPG")
seg <- readJPEG_bw("model_train/seg/train_5.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 400

Out5 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_5.JPG", 
                               label_path = "model_train/label/train_5.JPG")




#################################################
##        training data ( from photo 6)        ##
#################################################
img <- readJPEG("model_train/img/train_6.JPG")
seg <- readJPEG_bw("model_train/seg/train_6.JPG")

plot(apply(seg, 1, mean), type = "l")
cut <- 350

Out6 <- create_training_sample(img, seg, l1, l2, cut, N = 1000, save_combine = TRUE,
                               save_label = TRUE, combine_path = "model_train/background_removed/train_6.JPG", 
                               label_path = "model_train/label/train_6.JPG")







X <- array(0, c(12000, 2*l1+1, 2*l2+1, 3))
X[1:2000,,,] <- Out1$X
X[2001:4000,,,] <- Out2$X
X[4001:6000,,,] <- Out3$X
X[6001:8000,,,] <- Out4$X
X[8001:10000,,,] <- Out5$X
X[10001:12000,,,] <- Out6$X



Y <- rep( rep(c(0, 1), each = 1000), 6 )









