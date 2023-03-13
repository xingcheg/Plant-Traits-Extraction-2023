# Plant-Traits-Extraction-2023

R code and associated files/data for the analysis from the paper "High-Throughput Phenotyping: A Self-Supervised Sequential CNN Method to Segment Overlapping Plants". by Xingche Guo, Yumou Qiu, Dan Nettleton, and Patrick S. Schnable.

## Before using
* Please install *Python* and *Tensorflow* in order to use API *Keras* in *R*.
* In order to install R package 'EBImage', check https://bioconductor.org/packages/release/bioc/html/EBImage.html.

## Overview
### SS_CNN.hdf5
The self-supervised sequential CNN (SS-CNN) model that trained by the example training data in *"model_train/img"* for early and late stage plant pixels classification.

### cnn_training_history.png
The plot of (loss/validation-loss/accuracy/validation-accuracy) versus 100 epoch for training *"SS_CNN.hdf5"*.


### model_train
Folder *"model_train"* includes the example training photos, the segmentation images, the background removed images, the labeled images, and R code that used to crop/label training data and train our SS-CNN model.

* **model_train/PlantMod2.hdf5** The trained KAT4IA model for field photo segmentation.
* **model_train/img**: field photos used for training.
* **model_train/seg**: segmented field images for training.
* **model_train/background_removed**: background-removed field photos used for training.
* **model_train/label**: labeled segmented field images used for training (red and blue represent foreground- and background-plant pixels).
* **model_train/segmentation_KAT4IA.R**: run this .R files to segment the example training photos in *"model_train/img"*, it returns segmented field images in *"model_train/seg"*.
* **model_train/plant_cropping_labeling.R**: run this .R files to prepare training data by labeling foreground- and background-plant pixels, sampling 2000 labeled pixels from each photo, and creating 33x33 cropped mini-images centered on each labeled pixel.
* **model_train/train_cnn_model.R**: run this .R files to train our proposed SS-CNN model.

### plant_separation
Folder *"plant_separation"* includes some example field photos captured by one of our cameras, the segmented photos, the late stage labeled field images, and R code that used to separate foreground- and background-plant pixels in the late growth stage.

* **segmentation/example_plant_photos**: some example raw field photos taken by one of our cameras.
* **segmentation/seg**: segmented field images.
* **segmentation/sep_late_stage_bw**: late stage segmented field images that only include extracted foreground-plant pixels.
* **segmentation/sep_late_stage_rgb**: late stage labeled field images with foreground- and background-plant pixels painted in red and blue.
* **segmentation/plant_separation.R**: this .R file is a pipline to separate foreground- and background-plant pixels of a sequence of plant field photos using our trained SS-CNN model.


### height_measurement
Folder "height_measurement" includes the algorithm for height extraction and curve fitting.

* **height_measurement/early_height_measure.R**: run this .R file to extract early stage plant heights from the segmented images.
* **height_measurement/late_height_measure.R**: run this .R file to extract late stage plant heights from the segmented images.
* **height_measurement/growth_curve_est.R**: run this .R file to fit growth curves for all foreground plants that uses early and late stage plant heights as input.
