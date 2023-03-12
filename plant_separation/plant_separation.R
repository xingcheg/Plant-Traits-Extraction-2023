# this .R file provide foreground- and background-plant separation
# in the late growth stage using the trained SS-CNN model, postprocessing 
# by Super-pixel is also included

library(jpeg)
library(EBImage)
library(keras)
library(OpenImageR)


mlp <- load_model_hdf5("SS_CNN.hdf5")


## read jpeg black and white image
readJPEG_bw  <- function(name) {
  out <- round( as.matrix(readJPEG(name)) )
  return( out )
}



testing_label_jpg <- function(img, seg, l1, l2, mlp, cut, thres){
  
  r <- dim(seg)[1]
  c <- dim(seg)[2]
  img <- resize(img, r, c)
  img_1 <- img
  img_1[,,1] <- img[,,1] * seg
  img_1[,,2] <- img[,,2] * seg
  img_1[,,3] <- img[,,3] * seg
  
  
  plant_ind <- which(seg[(l1+1):(r-l1), (l2+1):(c-l2)] == 1, arr.ind = TRUE)
  plant_ind[,1] <- plant_ind[,1] + l1
  plant_ind[,2] <- plant_ind[,2] + l2
  
  
  res_slic <- superpixels(input_image = img_1 * 255,
                          method = "slic",
                          superpixel = 2000, 
                          compactness = 0.025,
                          return_slic_data = TRUE,
                          return_labels = TRUE, 
                          write_slic = "", 
                          verbose = TRUE)
  
  slice_id <- as.numeric( names( table(res_slic$labels) ) )
  
  plant_ind1 <- NULL
  plant_label <- NULL
  
  for (i in 1:length(slice_id)){
    img_slice_ind <- which(res_slic$labels == slice_id[i], arr.ind = TRUE)
    plant_slice_ind <- plant_ind[(plant_ind[,1] %in% img_slice_ind[,1]) &
                                   (plant_ind[,2] %in% img_slice_ind[,2]),]
    
    nn <- nrow(plant_slice_ind)
    if (is.null(nn) == TRUE){
      nn <- 0
    }
    #cat(i, nn, "\n")
    if( nn > 0 ){
      Z <- as.numeric( plant_slice_ind[, 1] <= cut )
      X_test <- array(0, c(nn, 2*l1+1, 2*l2+1, 3))
      for (j in 1:nn){
        row <- plant_slice_ind[j,1]
        col <- plant_slice_ind[j,2]
        X_test[j, , , ] <- img_1[ (row-l1):(row+l1), (col-l2):(col+l2),]
      }
      
      if (nn >= 10){
        idx <- sample(nn, floor( nn^(0.75) ))
        X_test <- X_test[idx, , ,]
        Z <- Z[idx]
      }
  
      Y_test0 <- mlp %>% predict_classes(X_test)
      Y_test0 <- Y_test0 * Z
      Y_test <- rep(ifelse(mean(Y_test0)>(1-thres), 1, 0), nn)
      plant_ind1 <- rbind(plant_ind1, plant_slice_ind)
      plant_label <- c(plant_label, Y_test)
    }
  }
  
  img_r1 <- matrix(0, r, c)
  for (i in 1:length(plant_label)){
    row <- plant_ind1[i,1]
    col <- plant_ind1[i,2]
    img_r1[row, col] <- 1-plant_label[i]
  }
  
  img_r2 <- img
  for (i in 1:length(plant_label)){
    row <- plant_ind1[i,1]
    col <- plant_ind1[i,2]
    if (plant_label[i]==0){
      img_r2[row, col, 1] <- 1
      img_r2[row, col, 2] <- 0
      img_r2[row, col, 3] <- 0
    } else {
      img_r2[row, col, 1] <- 0
      img_r2[row, col, 2] <- 0
      img_r2[row, col, 3] <- 1
    }
  }
  
  return(list(result_bw = img_r1, result_rgb = img_r2))
  
}





testing_label_jpg_seq <- function(img_folder_path, seg_folder_path, 
                                  result_bw_folder_path, result_rgb_folder_path,
                                  l1=16, l2=16, mlp, cut, change_ind, thres){
  img_names <- list.files(path = img_folder_path)
  seg_names <- list.files(path = seg_folder_path)
  nn <- length(img_names)
  for (i in (change_ind+1):nn){
    tt1 <- Sys.time()
    img_name1 <- paste(img_folder_path, "/", img_names[i], sep = "")
    seg_name1 <- paste(seg_folder_path, "/", seg_names[i], sep = "")
    result_bw_name1 <- paste(result_bw_folder_path, "/", seg_names[i], sep = "")
    result_rgb_name1 <- paste(result_rgb_folder_path, "/", seg_names[i], sep = "")
    img<-readJPEG(img_name1) 
    seg <- readJPEG_bw(seg_name1)
    result <- testing_label_jpg(img, seg, l1, l2, mlp, cut, thres)
    result_bw <- result$result_bw
    result_rgb <- result$result_rgb
    tt2 <- Sys.time()
    cat("segmentation finished for:", img_names[i], 
        ";\t\t computation time=", tt2-tt1, "\n")
    writeJPEG(result_bw, result_bw_name1) 
    writeJPEG(result_rgb, result_rgb_name1) 
  }
}





img_folder_path <- "plant_separation/example_plant_photos"
seg_folder_path <- "plant_separation/seg"
result_bw_folder_path <- "plant_separation/sep_late_stage_bw"
result_rgb_folder_path <- "plant_separation/sep_late_stage_rgb"


source("height_measurement/early_height_measure.R")
xx <- height_measure_seq(seg_folder_path, cr10=0.1, cr11=0.025, cr12=0.075, sep1=10,
                         p = 2, cr20 = 0.2, sep2 = 50, cr31=0.1, cr32=0.1,
                         cr3=0.025)
xx$change_ind
xx$cut

testing_label_jpg_seq(img_folder_path, seg_folder_path, 
                      result_bw_folder_path, result_rgb_folder_path, l1=16, l2=16, 
                      mlp, cut = 380, change_ind = 29, thres = 0.8)




