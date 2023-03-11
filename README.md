# Plant-Traits-Extraction-2023

R code and associated files/data for the analysis from the paper "High-Throughput Phenotyping: A Self-Supervised Sequential CNN Method to Segment Overlapping Plants". by Xingche Guo, Yumou Qiu, Dan Nettleton, and Patrick S. Schnable.

## SS_CNN.hdf5
The self-supervised sequential CNN (SS-CNN) model that trained by the example training data in *model_train/img* for early and late stage plant pixels classification.

## cnn_training_history.png
The plot of (loss/validation-loss/accuracy/validation-accuracy) versus 100 epoch for training *SS_CNN.hdf5*.


## model_train
Folder "model_train" includes the example training photos, the segmentation images, the background removed images, the labeled images, and R code that used to crop/label training data and train our SS-CNN model.

* **model_train/PlantMod2.hdf5** The trained KAT4IA model for field photo segmentation.
* **model_train/img**: field photos used for training.
* **model_train/seg**: segmented field images for training.
* **model_train/background_removed**: background-removed field photos used for training.
* **model_train/label**: the labeled segmented field images used for training (red and blue represent foreground- and background-plant pixels).
* **model_train/segmentation_KAT4IA.R**: run this .R files to segment the example training photos in *model_train/img*, it returns segmented field images in *model_train/seg*.


## segmentation
Folder "segmentation" includes the field photos captured by one of our cameras, the segmented photos, and R code that used to segment the images.

* **segmentation/CAM322**: raw field photos taken by camera 322.
* **segmentation/CAM322_seg**: segmented field images for camera 322.
* **segmentation/seg_funcs.R**: this .R file is a pipline to segment a sequence of plant field photos.
* **segmentation/seg_funcs_parallel.R**: this .R file is a pipline to segment a sequence of plant field photos using parallel computing.

## height_measurement
Folder "height_measurement" includes the algorithm for height extraction and curve fitting, and one example growth curves fitting result.

* **height_measurement/height_measure.R**: run this .R file to extract plant heights from the segmented images and fit growth curves for the plants.
