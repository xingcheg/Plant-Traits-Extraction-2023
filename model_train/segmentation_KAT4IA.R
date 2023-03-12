# this .R file applied the KAT4IA method to segment field photos

library(EBImage)
library(png)
library(jpeg)
library(keras)


################## Functions ##################

## rgb image to n x 27 (features) matrix
img.to.mat.nbhd<-function(img){
  k<-1
  img.pad<-array(NA,dim=c(dim(img)[1]+2,dim(img)[2]+2,3))
  img.pad[,,1]<-cbind(0,rbind(0,img[,,1],0),0)
  img.pad[,,2]<-cbind(0,rbind(0,img[,,2],0),0)
  img.pad[,,3]<-cbind(0,rbind(0,img[,,3],0),0)
  img.mat<-matrix(NA,nrow=(dim(img)[1])*(dim(img)[2]),ncol=27)
  for(i in 2:(dim(img.pad)[1]-1)){
    for(j in 2:(dim(img.pad)[2]-1)){
      img.mat[k,]<-c(as.vector(img.pad[((i-1):(i+1)),((j-1):(j+1)),1]),
                     as.vector(img.pad[((i-1):(i+1)),((j-1):(j+1)),2]),
                     as.vector(img.pad[((i-1):(i+1)),((j-1):(j+1)),3]))
      k<-k+1
    }
  }
  return(img.mat)
}

## segmentation prediction
seg_pred <- function(nb, mlp, thres=0.5, dim_img){
  test.prob<-mlp %>% predict(nb)
  pts.nn.nb<-rep(0,times=length(test.prob))
  pts.nn.nb[test.prob>=thres]<-1
  
  img <- matrix(NA,dim_img[1],dim_img[2])
  for(i in 1:dim_img[1]){
    img[i,]<-pts.nn.nb[((i-1)*dim_img[2]+1):(i*dim_img[2])]
  }  
  return(img)
}

## segmentation for one folder (a sequence of plants) for .jpg
seg_seq_plant_jpg <- function(mlp, img_folder_path, seg_folder_path, dim_resize, thres=0.5){
  file_names <- list.files(path = img_folder_path)
  nn <- length(file_names)
  for (i in 1:nn){
    tt1 <- Sys.time()
    o_image_name <- paste(img_folder_path, "/", file_names[i], sep = "")
    r_image_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    ts.img<-readJPEG(o_image_name) 
    ts.img.rs<-resize(ts.img, dim_resize[1], dim_resize[2]) 
    ts.nb<-img.to.mat.nbhd(ts.img.rs)  
    predicted.image <- seg_pred(ts.nb, mlp, thres, dim_resize)
    tt2 <- Sys.time()
    cat("segmentation finished for:", file_names[i], 
        ";\t\t computation time=", tt2-tt1, "\n")
    writeJPEG(predicted.image, r_image_name) 
  }
}

## segmentation for one folder (a sequence of plants) for .jpg
seg_seq_plant_png <- function(mlp, img_folder_path, seg_folder_path, dim_resize, thres=0.5){
  file_names <- list.files(path = img_folder_path)
  nn <- length(file_names)
  for (i in 1:nn){
    tt1 <- Sys.time()
    o_image_name <- paste(img_folder_path, "/", file_names[i], sep = "")
    r_image_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    ts.img<-readPNG(o_image_name) 
    ts.img.rs<-resize(ts.img, dim_resize[1], dim_resize[2]) 
    ts.nb<-img.to.mat.nbhd(ts.img.rs)  
    predicted.image <- seg_pred(ts.nb, mlp, thres, dim_resize)
    tt2 <- Sys.time()
    cat("segmentation finished for:", file_names[i], 
        ";\t\t computation time=", tt2-tt1, "\n")
    writePNG(predicted.image, r_image_name) 
  }
}



################## Test Functions ###############
mlp <- load_model_hdf5(file = "model_train/PlantMod2.hdf5")
img_folder_path <- "model_train/img"
seg_folder_path <- "model_train/seg"

seg_seq_plant_jpg(mlp, img_folder_path, seg_folder_path, c(750, 1000), thres=0.5)



