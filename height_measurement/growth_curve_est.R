# this .R file prepares CNN training data by cropping and labeling 
# background-removed images
setwd("/Users/apple/Desktop/SS-CNN")

library(ggplot2)
source("height_measurement/early_height_measure.R")
source("height_measurement/late_height_measure.R")


## monotone spline regression function
monreg0 <- function(x, y, df=4, plot_it = FALSE){
  x <- as.numeric(x)
  N <- length(x)
  b <- max(x)
  a <- min(x)
  x <- (x-a)/(b-a)
  fit <- smooth.spline(x, y, df = df)
  pts <- (1:N)/N
  mu0 <- predict(fit, newdata = data.frame(pts))$y
  mu0_diff <- mu0[-1] - mu0[-N]
  use_monreg <- any(mu0_diff < 0)
  if (use_monreg){
    d <- density(mu0, kernel = "gaussian", n=1e4)
    t <- d$x
    delta <- t[2]-t[1]
    pdf <- d$y
    cdf <- cumsum(pdf) * delta
    out <- rep(0, N)
    for (i in 1:N){
      ind <- which.min(abs(cdf-x[i]))
      out[i] <- t[ind]
    }
  } else {
    out <- predict(fit, newdata = data.frame(x))$y
  }
  if (plot_it == TRUE){
    plot(x, y)
    lines(fit, col = "red")
    if (use_monreg){
      lines(x, out, col = "blue")
    }
  }
  return(out)
}


## outlier detection function
outlier_detect <- function(resid, C){
  q1 <- quantile(resid, 0.25)
  q3 <- quantile(resid, 0.75)
  iqr <- q3 - q1
  lb <- q1 - C * iqr
  ub <- q3 + C * iqr
  outlier <-  (resid < lb) | (resid > ub)
  return(outlier)
}



## estimate early stage plant heights
path_seg <- "plant_separation/seg"

xx <- height_measure_seq(path_seg, cr10=0.1, cr11=0.025, cr12=0.075, sep1=10,
                         p = 2, cr20 = 0.2, sep2 = 50, cr31=0.1, cr32=0.1,
                         cr3=0.025)


## estimate late stage plant heights
path_sep <- "plant_separation/sep_late_stage_bw"
xx1 <- height_measure_late_seq(path_sep, K=xx$K, cr11=0.075, cr12=0.025,
                               p = 2, cr20 = 0.4, sep = 30, cr31=0.15, cr32=0.15,
                               cr33=0.025, cr34=0.01)




## growth curve estimation and visualization
DD <- NULL
for (i in 1:xx$K){
  dd1 <- data.frame(time = xx$time, 
                    height = xx$height_early[i,],
                    stage = rep("early", length(xx$time)),
                    pos = rep(i, length(xx$time)))
  
  time1 <- xx1$time[xx1$time < "2017-08-10 08:00:00 CDT"]
  height_late1 <- xx1$height_late[,xx1$time < "2017-08-10 08:00:00 CDT"]
  dd2 <- data.frame(time = time1, 
                    height = height_late1[i,],
                    stage = rep("late", length(time1)),
                    pos = rep(i, length(time1)))
  dd <- rbind(dd1, dd2)
  
  x <- dd$time 
  y <- dd$height
  na_idx <- is.na(y)
  x <- x[!na_idx]
  y <- y[!na_idx]
  fit <- smooth.spline(x, y, df = 4.5)
  yhat <- predict(fit, newdata = data.frame(x))$y
  resid <- y - yhat
  outlier <- outlier_detect(resid, 2.5)
  x1 <- x[!outlier]
  y1 <- y[!outlier]
  yhat1 <- monreg0(x1, y1, df=4.5, plot_it = FALSE)
  idx_use <- {(!na_idx) & (!outlier)}
  dd <- data.frame(dd[idx_use,], curve = yhat1)
  DD <- rbind(DD, dd)
  
}


DD$pos <- as.factor(DD$pos)



ggplot(data=DD) + 
  geom_point(aes(x = time, y = height, colour = stage), size = 0.8) + 
  geom_line(aes(x = time, y = curve), size = 1.1) + 
  facet_wrap(~pos, nrow=2) + 
  xlab("Date") + 
  ylab("Height") + 
  theme_bw(base_size = 14) + 
  guides(fill=guide_legend(title="Stage"))
  

