#!/bin/sh
grass
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B1.TIF output=L8_2014_01 extent=region resolution=region --overwrite
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B2.TIF output=L8_2014_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B3.TIF output=L8_2014_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B4.TIF output=L8_2014_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B5.TIF output=L8_2014_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B6.TIF output=L8_2014_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20140330_20200912_02_T1_SR_B7.TIF output=L8_2014_07 extent=region resolution=region
#
g.list rast
#
# ----CREATING COLOR COMPOSITES-------------------------->
# false color
r.composite blue=L8_2014_01 green=L8_2014_02 red=L8_2014_03 output=L8_2014_123 --overwrite
d.mon wx0
d.rgb blue=L8_2014_02 green=L8_2014_03 red=L8_2014_04
#
r.composite blue=L8_2014_02 green=L8_2014_03 red=L8_2014_04 output=L8_2014_234 --overwrite
d.mon wx1
d.rast L8_2014_234
d.out.file output=Bangladesh_123 format=jpg --overwrite
#
# false color
r.composite blue=L8_2014_07 green=L8_2014_06 red=L8_2014_04 output=L8_2014_764 --overwrite
d.mon wx0
d.rast L8_2014_764
d.out.file output=Bangladesh_753 format=jpg --overwrite
#
r.composite blue=L8_2014_03 green=L8_2014_04 red=L8_2014_07 output=L8_2014_347 --overwrite
d.mon wx0
d.rast L8_2014_347
d.out.file output=Bangladesh_347 format=jpg --overwrite
#
r.composite blue=L8_2014_02 green=L8_2014_04 red=L8_2014_07 output=L8_2014_247 --overwrite
d.mon wx0
d.rast L8_2014_247
d.out.file output=Bangladesh_247 format=jpg --overwrite
#
r.composite blue=L8_2014_03 green=L8_2014_07 red=L8_2014_04 output=L8_2014_374 --overwrite
d.mon wx0
d.rast L8_2014_374
d.out.file output=Bangladesh_374 format=jpg --overwrite
#
# false color: NIR band B05 in the red channel, B04 in the green and B03 in the blue
r.composite blue=L8_2014_03 green=L8_2014_04 red=L8_2014_05 output=L8_2014_345 --overwrite
d.mon wx0
d.rast L8_2014_345
d.out.file output=Bangladesh_345 format=jpg --overwrite
# true color
r.composite blue=L8_2014_02 green=L8_2014_03 red=L8_2014_04 output=L8_2014_234 --overwrite
d.mon wx0
d.rast L8_2014_234
d.out.file output=Bangladesh_J_234 format=jpg --overwrite

# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L8_2014_01 -p
# grouping data by i.group
i.group group=L8_2014 subgroup=res_30m \
  input=L8_2014_01,L8_2014_02,L8_2014_03,L8_2014_04,L8_2014_05,L8_2014_06,L8_2014_07 --overwrite
#
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L8_2014 subgroup=res_30m \
  signaturefile=cluster_L8_2014 \
  classes=10 reportfile=rep_clust_L8_2014.txt --overwrite

# Classification by i.maxlik module
i.maxlik group=L8_2014 subgroup=res_30m \
  signaturefile=cluster_L8_2014 \
  output=L8_2014_cluster_classes reject=L8_2014_cluster_reject --overwrite
# Mapping
g.region raster=L8_2014_01 -p
d.mon wx0
g.region raster=L8_2014_cluster_classes -p
r.colors L8_2014_cluster_classes color=bcyr
d.rast L8_2014_cluster_classes
d.legend raster=L8_2014_cluster_classes title="30 March 2014" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=Bangladesh_2014_mar format=jpg --overwrite
# Mapping rejection probability
d.mon wx1
g.region raster=L8_2014_cluster_classes -p
# r.colors L8_2014_cluster_reject color=wave -e
r.colors L8_2014_cluster_reject color=rainbow -e
d.rast L8_2014_cluster_reject
d.legend raster=L8_2014_cluster_reject title="30 March 2014" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=Bangladesh_2014_reject format=jpg --overwrite
#
# --------------------------------------------->
# MACHINE LEARNING
#
# g.list rast
g.region raster=L8_2014_01 -p
# Generating some training pixels from an older land cover classification:
r.random input=L8_2014_cluster_classes seed=100 npoints=1000 raster=training_pixels --overwrite
# Creating the imagery group with all Landsat-8 OLI/TIRS bands:
i.group group=L8_2014 input=L8_2014_01,L8_2014_02,L8_2014_03,L8_2014_04,L8_2014_05,L8_2014_06,L8_2014_07 --overwrite
# Using these training pixels to perform a classification on recent Landsat image:
# train a decision tree classification model using r.learn.train
r.learn.train group=L8_2014 training_map=training_pixels \
    model_name=DecisionTreeClassifier n_estimators=500 save_model=rf_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L8_2014 load_model=rf_model.gz output=rf_classification --overwrite
# check raster categories automatically applied to the classification output
r.category rf_classification
# copy color scheme from landclass training map to result
r.colors rf_classification raster=training_pixels
# display
d.mon wx0
d.rast rf_classification
r.colors rf_classification color=roygbiv -e
d.legend raster=rf_classification title="Decision Tree: 01/2023" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=DT_2023_01 format=jpg --overwrite
#
# training a extra trees classification model using r.learn.train
r.learn.train group=L8_2014 training_map=training_pixels \
    model_name=ExtraTreesClassifier n_estimators=500 save_model=rf_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L8_2014 load_model=rf_model.gz output=rf_classification --overwrite
# check raster categories - they are automatically applied to the classification output
r.category rf_classification
# copy color scheme from landclass training map to result
r.colors rf_classification raster=training_pixels
# display
d.mon wx0
d.rast rf_classification
r.colors rf_classification color=bgyr -e
d.legend raster=rf_classification title="Extra Tree: 01/2023" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=ET_2023_01 format=jpg --overwrite
