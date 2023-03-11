# this .R file is used to compute the plant heights from the segmented images
# in the early growth stage using KAT4IA method

library(EBImage)
library(jpeg)
library(changepoint)


###################################################
#####             Help Functions              #####
###################################################

## read jpeg black and white image
readJPEG_bw  <- function(name) {
  out <- round( as.matrix(readJPEG(name)) )
  return( out )
}

## mode function
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

## change file names and record 
change_name <- function(name0){
  name1 <- sub(".*_", "", name0)
  name2 <- sub("[\\.].*", "", name1)
  return(name2)
}


## change file names into time
find_time <- function(img_folder_path){
  file_names <- list.files(path = img_folder_path)
  nn <- length(file_names)
  time <- NULL
  for (i in 1:nn){
    time <- c(time,
              change_name(file_names[i])
    )
  }
  return(as.POSIXlt(time,format="%Y-%m-%d-%H-%M"))
}


###################################################
#####               Early Stage               #####
###################################################

## find first row peak  
first_row_peak <- function(img, cr0=0.2, cr1=0.05, cr2=0.075, sep=10){
  n1 <- nrow(img)
  row_mean <- apply(img, 1, mean)[n1:1]                            
  D_row_mean <- data.frame(x = 1:n1, y = row_mean)
  s_row_mean <- predict(loess(y~x,data = D_row_mean, span = 0.05), 
                        D_row_mean$x)
  s_row_mean <- pmax(s_row_mean, 0)
  ind1 <- which( s_row_mean > max(s_row_mean) * cr0 )              
  temp <- which( (ind1[-1]-ind1[-length(ind1)]) > sep )
  if (length(temp)==0){
    ind2 <- ind1[length(ind1)]                                      
  } else {                                                       
    ind2 <- temp[1]                                            
  }
  ind3 <- which.max(s_row_mean[ind1][1:ind2])                   
  ind_peak <- ind1[ind3]                                 
  ind_lb <- which(s_row_mean[1:ind_peak] > cr1 * s_row_mean[ind_peak])[1]
  if (is.na(ind_lb)){
    ind_lb <- 1                                  
  }       
  ind_ub <- ind_peak + which( s_row_mean[ ind_peak:n1 ] < cr2 * s_row_mean[ind_peak] )[1] 
  if (is.na(ind_ub)){
    ind_ub <- n1
  }
  return( c(n1 - ind_ub + 1, n1 - ind_lb + 1) )
}


## find when to stop recording (first and second row not separable)
find_stop_place <- function(seg_folder_path, cr10=0.2, cr11=0.05, cr12=0.075, sep1=10, time0){
  file_names <- list.files(path = seg_folder_path)
  nn <- length(file_names)
  height <- rep(0, nn)
  cut <- matrix(0, nn, 2)
  for (i in 1:nn){
    seg_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    seg <- readJPEG_bw(seg_name) 
    cut_ind <- first_row_peak(seg, cr10, cr11, cr12, sep1)
    height[i] <- cut_ind[2] - cut_ind[1]
    cut[i,] <- cut_ind
  }
  change_ind <- cpts(cpt.mean(height, Q=1))-1
  bound <- quantile(height[-(1:change_ind)], 0.5)
  plant_use_ind <- which(height[1:change_ind] < bound)
  ## plot 
  plot(time0, height, pch = 16, xlab = "time", ylab = "row height", 
       main = "Change Point Detection")
  points(time0[plant_use_ind], height[plant_use_ind], pch = 16, col = "red")
  abline(v = as.POSIXct(time0[change_ind]), col = "red")
  abline(h = bound, col = "red")
  
  return(list(change_ind = change_ind, height = height, 
              cut = cut, plant_use_ind = plant_use_ind))
}


## column cut
column_peaks <- function(img, row_ind, p, cr0, sep){
  img1 <- img[ row_ind, ]
  col_mean <- apply(img1, 2, mean)
  ind1 <- which( col_mean^p > max(col_mean^p) * cr0 )
  ind2 <- which( (ind1[-1] - ind1[-length(ind1)]) > sep )
  n_peak <- length(ind2) + 1
  if (n_peak == 1){
    final_cut <- c(1, ncol(img))
  } else {
    ind2 <- c(0, ind2, length(ind1))
    col_peaks <- NULL
    for (i in 1:(n_peak)){
      ind3 <- which.max(col_mean[ind1][(ind2[i]+1):(ind2[i+1])])
      col_peaks[i] <- ind1[(ind2[i]+1):(ind2[i+1])][ind3]
    }
    final_cut0 <- floor( (col_peaks[-1] + col_peaks[-n_peak])/2 )
    final_cut <- c(1,  final_cut0, ncol(img))
  }
  
  return(list(n_plant = n_peak, col_cuts = final_cut))
  
}


## height measurement for one plant (img = img for single plant)
height_measure_early <- function(img, cr1 = 0.1, cr2 = 0.1, cr = 0.05){
  if (sum(img) == 0){
    return(c(NA, NA, NA))
  }
  else{
    n1 <- nrow(img)
    n2 <- ncol(img)
    col_mean <- apply(img, 2, mean)
    max_col <- max(col_mean)
    m_ind <- which.max(col_mean)
    flag_lb <- col_mean[1:m_ind] < cr1 * max_col
    col_lb <- ifelse(sum(flag_lb)>0, which(flag_lb)[sum(flag_lb)], 1)
    flag_ub <- col_mean[m_ind:n2] < cr2 * max_col
    col_ub <- ifelse(sum(flag_ub)>0, which(flag_ub)[1]+m_ind-1, n2)
    
    row_mean <- apply(img[,col_lb:col_ub], 1, mean)
    max_row <- max(row_mean)
    plant_rows <- which(row_mean > cr * max_row)
    row_lb <- plant_rows[1]
    row_ub <- plant_rows[length(plant_rows)]
    return(c(m_ind, row_lb, row_ub))
  }
}


## height measurement for a sequence of photos
height_measure_seq <- function(seg_folder_path, cr10=0.1, cr11=0.025, cr12=0.075, sep1=10,
                               p = 2, cr20 = 0.2, sep2 = 50, cr31=0.1, cr32=0.1,
                               cr3=0.05){
  file_names <- list.files(path = seg_folder_path)
  time0 <- find_time(seg_folder_path)
  
  par(mfrow = c(1,2))
  x.list <- find_stop_place(seg_folder_path, cr10, cr11, cr12, sep1, time0)
  change_ind <- x.list$change_ind
  height <- x.list$height
  row_cut <- x.list$cut
  plant_use_ind <- x.list$plant_use_ind
  cut <- row_cut[plant_use_ind[length(plant_use_ind)], 1] + 20
  
  height_early.list <- vector("list", length(plant_use_ind))
  nplant.list <- vector("list", length(plant_use_ind))
  
  for (i in plant_use_ind){
    seg_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    seg <- readJPEG_bw(seg_name) 
    row_ind <- row_cut[i,1]:row_cut[i,2]
    y.list <- column_peaks(seg, row_ind, p, cr20, sep2)
    n_plant <- y.list$n_plant
    col_cuts <- y.list$col_cuts
    
    hh <- rep(0, n_plant)
    for (j in 1:n_plant){
      col_ind <- col_cuts[j]:col_cuts[j+1]
      seg_single <- seg[row_ind, col_ind]
      para1 <- height_measure_early(seg_single, cr31, cr32, cr3)
      hh[j] <- para1[3] - para1[2]
    }
    
    i1 <- which(i==plant_use_ind)
    nplant.list[[i1]] <- n_plant
    height_early.list[[i1]] <- hh
  }
  
  plant_num <- Mode(unlist(nplant.list))
  height_early <- matrix(unlist(height_early.list[unlist(nplant.list)==plant_num]), 
                       nrow=plant_num)
  
  plot(time0[plant_use_ind], unlist(nplant.list), 
       xlab = "time", ylab = "number of plants",
       main = "Check Number of Plants", 
       pch = 16, col = ifelse(unlist(nplant.list) == plant_num, 2, 1))
  
  par(mfrow = c(1,1))
  
  time <- time0[plant_use_ind][unlist(nplant.list)==plant_num]
  return(list(time=time, height_early=height_early, K=plant_num,
              change_ind=change_ind, cut = cut))
}




