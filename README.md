# Plant-Traits-Extraction-2023

R code and associated files/data for the analysis from the paper "High-Throughput Phenotyping: A Self-Supervised Sequential CNN Method to Segment Overlapping Plants". by Xingche Guo, Yumou Qiu, Dan Nettleton, and Patrick S. Schnable.

## PlantMod2.hdf5
The trained self-supervised learning model for field photo segmentation.

## model_train
Folder "model_train" includes the cropped plant and background images and R code that used to train our self-superviesd learning model for plant segmentation.

* **model_train/data**: training images (both background and plant).
* **model_train/background_labeling.R** and **model_train/plant_labeling.R**: run these two .R files to create plant and background features and labels for neural network training.
* **model_train/train_seg_model.R**: run this .R files to train our segmentation model.

## segmentation
Folder "segmentation" includes the field photos captured by one of our cameras, the segmented photos, and R code that used to segment the images.

* **segmentation/CAM322**: raw field photos taken by camera 322.
* **segmentation/CAM322_seg**: segmented field images for camera 322.
* **segmentation/seg_funcs.R**: this .R file is a pipline to segment a sequence of plant field photos.
* **segmentation/seg_funcs_parallel.R**: this .R file is a pipline to segment a sequence of plant field photos using parallel computing.

## height_measurement
Folder "height_measurement" includes the algorithm for height extraction and curve fitting, and one example growth curves fitting result.

* **height_measurement/height_measure.R**: run this .R file to extract plant heights from the segmented images and fit growth curves for the plants.
