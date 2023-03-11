# this .R file is used to compute the plant heights from the segmented images
# in the late growth stage using our proposed method


###################################################
#####                Late Stage               #####
###################################################

## row cut algorithm for one photo
row_cut_late <- function(img, cr1=0.075, cr2=0.025){
  n1 <- dim(img)[1]
  row_mean <- apply(img, 1, mean)                           
  D_row_mean <- data.frame(x = 1:n1, y = row_mean)
  s_row_mean <- predict(loess(y~x,data = D_row_mean, span = 0.05), 
                        D_row_mean$x)
  s_row_mean <- pmax(s_row_mean, 0)
  ind_peak <- which( s_row_mean == max(s_row_mean) )[1]
  idx1 <- which(s_row_mean[1:ind_peak] < cr1 *  max(s_row_mean))
  idx2 <- ind_peak + which( s_row_mean[ ind_peak:n1 ] < cr2 *  max(s_row_mean) ) - 1
  ind_lb <- ifelse(length(idx1)>0, max(idx1), 1)
  ind_ub <- ifelse(length(idx2)>0, min(idx2), n1)
  return(c(ind_lb, ind_ub))
}


## row cut algorithm 
row_cut_late_seq <- function(seg_folder_path, cr1=0.075, cr2=0.025){
  file_names <- list.files(path = seg_folder_path)
  nn <- length(file_names)
  height <- rep(0, nn)
  cut <- matrix(0, nn, 2)
  for (i in 1:nn){
    seg_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    seg <- readJPEG_bw(seg_name) 
    cut_ind <- row_cut_late(seg, cr1, cr2)
    height[i] <- cut_ind[2] - cut_ind[1]
    cut[i,] <- cut_ind
  }
  return(list(cut = cut, height = height))
}


## column cut for a sequence of photos
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
height_measure_late <- function(img, cr1 = 0.1, cr2 = 0.1, cr3 = 0.05, cr4 = 0.025){
  if (sum(img) == 0){
    return(c(NA, NA, NA))
  }
  else{
    n1 <- nrow(img)
    n2 <- ncol(img)
    col_mean <- apply(img, 2, mean)
    col_mean1 <- apply(img[floor(n1/2):n1,], 2, mean)
    max_col <- max(col_mean)
    m_ind <- which.max(col_mean1)
    flag_lb <- col_mean[1:m_ind] < cr1 * max_col
    col_lb <- ifelse(sum(flag_lb)>0, which(flag_lb)[sum(flag_lb)], 1)
    flag_rb <- col_mean[m_ind:n2] < cr2 * max_col
    col_rb <- ifelse(sum(flag_rb)>0, which(flag_rb)[1]+m_ind-1, n2)
    if (col_lb==col_rb){
      row_mean <- img[,col_lb]
    } else {
      row_mean <- apply(img[,col_lb:col_rb], 1, mean)
    }
    max_row <- max(row_mean)
    m_ind_row <- which.max(row_mean)
    flag_lb_row <- row_mean[1:m_ind_row] < cr3 * max_row
    row_lb <- ifelse(sum(flag_lb_row)>0, which(flag_lb_row)[sum(flag_lb_row)], 1)
    flag_ub_row <- row_mean[m_ind_row:n1] < cr4 * max_row
    row_ub <- ifelse(sum(flag_ub_row)>0, which(flag_ub_row)[1]+m_ind_row-1, n1)
    return(c(m_ind, row_lb, row_ub))
  }
}


## height measurement for a sequence of photos
height_measure_late_seq <- function(seg_folder_path, K, cr11=0.075, cr12=0.025,
                                    p = 1, cr20 = 0.4, sep = 30, cr31=0.1, cr32=0.1,
                                    cr33=0.05, cr34=0.025){
  file_names <- list.files(path = seg_folder_path)
  time0 <- find_time(seg_folder_path)
  
  x.list <- row_cut_late_seq(seg_folder_path, cr11, cr12)
  row_cut <- x.list$cut
  height_late <- rep(0, length(file_names))
  
  height_late.list <- vector("list", length(file_names))
  nplant.list <- vector("list", length(file_names))
  
  for (i in 1:length(file_names)){
    seg_name <- paste(seg_folder_path, "/", file_names[i], sep = "")
    seg <- readJPEG_bw(seg_name) 
    row_ind <- row_cut[i,1]:row_cut[i,2]
    y.list <- column_peaks(seg, row_ind, p, cr20, sep)
    n_plant <- y.list$n_plant
    col_cuts <- y.list$col_cuts
    hh <- rep(0, n_plant)
    
    for (j in 1:n_plant){
      col_ind <- col_cuts[j]:col_cuts[j+1]
      seg_single <- seg[row_ind, col_ind]
      para1 <- height_measure_late(seg_single, cr31, cr32, cr33, cr34)
      hh[j] <- para1[3] - para1[2]
    }
    nplant.list[[i]] <- n_plant
    height_late.list[[i]] <- hh
  }
  
  plant_use_ind <- which(unlist(nplant.list)==K)
  height_late <- matrix(unlist(height_late.list[plant_use_ind]), 
                         nrow=K)
  
  
  plot(time0, unlist(nplant.list), 
       xlab = "time", ylab = "number of plants",
       main = "Check Number of Plants", 
       pch = 16, col = ifelse(unlist(nplant.list) == K, 2, 1))
  
  return(list(time=time0[plant_use_ind], height_late=height_late))
}

