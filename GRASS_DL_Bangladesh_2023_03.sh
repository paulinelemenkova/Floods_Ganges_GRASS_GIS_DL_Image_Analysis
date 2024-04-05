#!/bin/sh

grass
# ----IMPORT AND PREPROCESSING-------------------------->
# g.mapset location=Bangladesh mapset=PERMANENT

g.list rast
# importing the image subset with 7 Landsat bands and display the raster map
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B1.TIF output=L8_2023_M_01 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B2.TIF output=L8_2023_M_02 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B3.TIF output=L8_2023_M_03 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B4.TIF output=L8_2023_M_04 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B5.TIF output=L8_2023_M_05 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B6.TIF output=L8_2023_M_06 extent=region resolution=region
r.import input=/Users/polinalemenkova/grassdata/Bangladesh/LC08_L2SP_137044_20230307_20230316_02_T1_SR_B7.TIF output=L8_2023_M_07 extent=region resolution=region
#
g.list rast
#
# ----CREATING COLOR COMPOSITES-------------------------->
# false color
r.composite blue=L8_2023_M_07 green=L8_2023_M_05 red=L8_2023_M_03 output=L8_2023_M_753 --overwrite
d.mon wx0
d.rast L8_2023_M_753
d.out.file output=Bangladesh_753 format=jpg --overwrite
# false color
r.composite blue=L8_2023_M_03 green=L8_2023_M_04 red=L8_2023_M_05 output=L8_2023_M_345 --overwrite
d.mon wx0
d.rast L8_2023_M_345
d.out.file output=Bangladesh_345 format=jpg --overwrite
# true color
r.composite blue=L8_2023_M_02 green=L8_2023_M_03 red=L8_2023_M_04 output=L8_2023_M_234 --overwrite
d.mon wx0
d.rast L8_2023_M_234
d.out.file output=Bangladesh_J_234 format=jpg --overwrite

# ---CLUSTERING AND CLASSIFICATION------------------->
# Set computational region to match the scene
g.region raster=L8_2023_M_01 -p
# grouping data by i.group
i.group group=L8_2023_M subgroup=res_30m \
  input=L8_2023_M_01,L8_2023_M_02,L8_2023_M_03,L8_2023_M_04,L8_2023_M_05,L8_2023_M_06,L8_2023_M_07 --overwrite
# Clustering: generating signature file and report using k-means clustering algorithm
i.cluster group=L8_2023_M subgroup=res_30m \
  signaturefile=cluster_L8_2023_M \
  classes=10 reportfile=rep_clust_L8_2023_M.txt --overwrite
# Classification by i.maxlik module
i.maxlik group=L8_2023_M subgroup=res_30m \
  signaturefile=cluster_L8_2023_M \
  output=L8_2023_M_cluster_classes reject=L8_2023_M_cluster_reject --overwrite
# Mapping
g.region raster=L8_2023_M_01 -p
d.mon wx0
g.region raster=L8_2023_M_cluster_classes -p
r.colors L8_2023_M_cluster_classes color=bcyr
d.rast L8_2023_M_cluster_classes
d.legend raster=L8_2023_M_cluster_classes title="07 March 2023" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=Bangladesh_2023_mar format=jpg --overwrite
# Mapping rejection probability
d.mon wx1
g.region raster=L8_2023_M_cluster_classes -p
r.colors L8_2023_M_cluster_reject color=rainbow -e
d.rast L8_2023_M_cluster_reject
d.legend raster=L8_2023_M_cluster_reject title="07 March 2023" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=Bangladesh_2023_M_reject format=jpg --overwrite
# --------------------------------------------->
# MACHINE LEARNING
# g.list rast
g.region raster=L8_2023_M_01 -p
# Generate training pixels from an older land cover classification:
r.random input=L8_2014_M_cluster_classes seed=100 npoints=1000 raster=training_pixels --overwrite
# Create the imagery group with all Landsat-8 OLI/TIRS bands:
i.group group=L8_2023_M input=L8_2023_M_01,L8_2023_M_02,L8_2023_M_03,L8_2023_M_04,L8_2023_M_05,L8_2023_M_06,L8_2023_M_07 --overwrite
# Use these training pixels to perform a classification on recent Landsat image:
# train a MLPClassifier model using r.learn.train
r.learn.train group=L8_2023_M training_map=training_pixels \
    model_name=GaussianNB n_estimators=500 save_model=mlpc_model.gz --overwrite
# perform prediction using r.learn.predict
r.learn.predict group=L8_2023_M load_model=mlpc_model.gz output=mlpc_classification --overwrite
# check raster categories automatically applied to the classification output
r.category mlpc_classification
# copy color scheme from landclass training map to result
r.colors mlpc_classification raster=training_pixels
# display
d.mon wx0
d.rast mlpc_classification
r.colors mlpc_classification color=roygbiv -e
d.legend raster=mlpc_classification title="MLPClassifier: 03/2022" title_fontsize=14 font="Helvetica" fontsize=12 bgcolor=white border_color=white
d.out.file output=MLPC_2023_03 format=jpg --overwrite
