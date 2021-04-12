###SDM Clean Script

##Set your working directory

##Required Libraries
library(dismo)
library(jsonlite)
library(sp)
library(raster)
library(maptools)
library(vegan)
library(rgdal)
library(rworldmap)
library(RColorBrewer)
library(ggmap)
library(rJava)
library(plotKML)
library(rgeos)
library(SSDM)
library(earth)
library(na.tools)
library(GISTools)
library(reshape2)


##Load in the enviornmental variables
cloud=raster("meanannualcloudfrequency.tif")
aspect=raster("aspect.tif")
precip=raster("precipdriestquarter.tif")
dist=raster("distancetoriver.tif")
dem=raster("elevation.tif")
tpi=raster("TPI.tif")
slope=raster("slope.tif")

##Create a raster stack
new14=stack(cloud, aspect, precip, dist, dem, tpi, slope)

##Crop and Mask the raster stack to the study site
#You will need to update the dsn to show the filepath on you computer
mask1=readOGR(dsn="StudySite.shp", layer="StudySite")
mask1
MASK3=crop(new14, mask1, filename="Cropped_Raster_Stack_1", snap='near', overwrite=T)
plot(MASK3)
MASK2=raster::mask(x= MASK3, mask= mask1, filename="Mask_predictors_14", overwrite=T, format="GTiff") 

#Check for collinearity
C=layerStats(MASK2, 'pearson', na.rm=T)
C1=as.data.frame(C)
write.csv(C1, file="Collinearity_1.csv")


###Load in your presence point data and filter them to the same resolution as your raster stack
humans.occ.21 <- load_occ(path = getwd(),
                          Env = MASK2,
                          file = "ArcheologicalSites.csv",
                          Xcol = "Longitude",
                          Ycol = "Latitude",
                          header = TRUE,
                          sep = ",",
                          Spcol = NULL,
                          GeoRes = TRUE,
                          reso = max(res(Env@layers[[1]])),
                          verbose = TRUE,
                          GUI = FALSE)

##Run the ensemble model 
ancient.peeps7 <- ensemble_modelling(algorithms = c("GAM","RF","MAXENT"),
                                     Occurrences = humans.occ.21,
                                     Env = MASK2,
                                     name = "Ancient_People_32_No_Col",
                                     Xcol = "Longitude",
                                     Ycol = "Latitude",
                                     rep = 5,
                                     PA=list(nb=1965, strat="random"),
                                     save = TRUE,
                                     thresh = 1001,
                                     ensemble.thresh = 0.65,
                                     path = getwd(),
                                     cv = "k-fold",
                                     cv.param = c(5, 5))
plot(ancient.peeps7)