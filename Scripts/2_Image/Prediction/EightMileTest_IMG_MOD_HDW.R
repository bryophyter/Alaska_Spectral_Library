#################################Models for headwall imagery######################################################
###Inputs from this model were made in Scripts/2_Image_processing/Headwall_Predictors/EightMileTest_IMG_ALL_Preds_HDW
library(spectrolab)
library(randomForest)
library(raster)
library(tidyverse)
library(hsdar)
library(randomcoloR)
library(randomForestExplainer)

##Reads in imagery so we can grab the crs to create our raster later
EightMileTest_HDW<-brick("Original_data/Headwall/EightMile_TSTIMG")
EightMileTest_HDW_latlong<-EightMileTest_HDW%>%rasterToPoints()%>%as.data.frame()

##This is a dataframe with all predictors to be used in model building
EightMileTest_data_HDW<-read.csv("Outputs/2_Imagery/Headwall/Processing/EightMileTest_data_HDW.csv")

##Lets load our random Forest model with the 50 most important variables (PFT_3)
load("Outputs/1_Field_spec/2_Models/Headwall/rf_HDW50.rda")
##rf_HDW50

##This function uses the model built on the  from spectral 50 most important variables
##to predict the observations of each pixel in the imagery
Results_HDW    <-predict(rf_HDW50,EightMileTest_data_HDW[-1:-2])

##Converts prediction from rf model to dataframe and changes column name to predicted
Results_HDW<-as.data.frame(Results_HDW)%>%'names<-'("predicted")

## Grabs x, y values from original image and combines with unique values from prediction 
Results_HDW<-cbind(Results_HDW,EightMileTest_HDW_latlong[1:2]) %>% dplyr::select(predicted,x,y)

###Creates Unique PFT_IDs
Unique_HDW<-unique(as.data.frame(Results_HDW$predicted)) 
Unique_HDW$PFT_ID<-seq(1:nrow(Unique_HDW))
names(Unique_HDW)[1]<-"predicted"

###Create dataframe with unique PFT_ID values and location info
Results_HDW<-merge(Results_HDW,Unique_HDW, by="predicted")%>% dplyr::select(x,y,PFT_ID)

##Converts dataframe to a raster for predicted layer....and use as.factor to arrange my original raster layer
EightMileTest_raster<-rasterFromXYZ(Results_HDW, crs = crs(EightMileTest_HDW)) 

##################################################Raster #1#####################################################
Graminoid_Sedge   <-subset(Unique_HDW,Unique_HDW$predicted=="Graminoid_Sedge")   %>%as.data.frame()%>%dplyr::select("PFT_ID")
Lichen_Yellow     <-subset(Unique_HDW,Unique_HDW$predicted=="Lichen_Yellow")     %>%as.data.frame()%>%dplyr::select("PFT_ID")
Shrub_Other       <-subset(Unique_HDW,Unique_HDW$predicted=="Shrub_Other")       %>%as.data.frame()%>%dplyr::select("PFT_ID")
Dwarf_Shrub_Needl <-subset(Unique_HDW,Unique_HDW$predicted=="Dwarf_Shrub_Needl") %>%as.data.frame()%>%dplyr::select("PFT_ID")
Dwarf_Shrub_Broad5<-subset(Unique_HDW,Unique_HDW$predicted=="Dwarf_Shrub_Broad5")%>%as.data.frame()%>%dplyr::select("PFT_ID")
Lichen_Dark       <-subset(Unique_HDW,Unique_HDW$predicted=="Lichen_Dark")       %>%as.data.frame()%>%dplyr::select("PFT_ID")
Shrub_Salix       <-subset(Unique_HDW,Unique_HDW$predicted=="Shrub_Salix")       %>%as.data.frame()%>%dplyr::select("PFT_ID")
Forb              <-subset(Unique_HDW,Unique_HDW$predicted=="Forb")              %>%as.data.frame()%>%dplyr::select("PFT_ID")
Tree_Needle       <-subset(Unique_HDW,Unique_HDW$predicted=="Tree_Needle")       %>%as.data.frame()%>%dplyr::select("PFT_ID")
Moss_Pleurocarp   <-subset(Unique_HDW,Unique_HDW$predicted=="Moss_Pleurocarp")   %>%as.data.frame()%>%dplyr::select("PFT_ID")
Shrub_Alder       <-subset(Unique_HDW,Unique_HDW$predicted=="Shrub_Alder")       %>%as.data.frame()%>%dplyr::select("PFT_ID")
Graminoid_Grass   <-subset(Unique_HDW,Unique_HDW$predicted=="Graminoid_Grass")   %>%as.data.frame()%>%dplyr::select("PFT_ID")
Lichen_Light      <-subset(Unique_HDW,Unique_HDW$predicted=="Lichen_Light")      %>%as.data.frame()%>%dplyr::select("PFT_ID")

###Filters the image on each functional group
EightMileTest_Graminoid_Sedge   <-EightMileTest_raster==Graminoid_Sedge   [1,1]
EightMileTest_Lichen_Yellow     <-EightMileTest_raster==Lichen_Yellow     [1,1]
EightMileTest_Shrub_Other       <-EightMileTest_raster==Shrub_Other       [1,1]
EightMileTest_Dwarf_Shrub_Needle<-EightMileTest_raster==Dwarf_Shrub_Needl [1,1]
EightMileTest_Dwarf_Shrub_Broad5<-EightMileTest_raster==Dwarf_Shrub_Broad5[1,1]
EightMileTest_Lichen_Dark       <-EightMileTest_raster==Lichen_Dark       [1,1]
EightMileTest_Shrub_Salix       <-EightMileTest_raster==Shrub_Salix       [1,1]
EightMileTest_Forb              <-EightMileTest_raster==Forb              [1,1]
EightMileTest_Tree_Needle       <-EightMileTest_raster==Tree_Needle       [1,1]
EightMileTest_Moss_Pleurocarp   <-EightMileTest_raster==Moss_Pleurocarp   [1,1]
EightMileTest_Shrub_Alder       <-EightMileTest_raster==Shrub_Alder       [1,1]
EightMileTest_Graminoid_Grass   <-EightMileTest_raster==Graminoid_Grass   [1,1]
EightMileTest_Lichen_Light      <-EightMileTest_raster==Lichen_Light      [1,1]

##We need to change all those values within the raster to 1, 
##so the sum of all the pixels in each quadrat can be calculated later
EightMileTest_denom  <-EightMileTest_raster>=1

##DF OF METEDATA
EightMileTest_meta  <-EightMileTest_quadrats@data%>%as.data.frame()

#Creates object with the total Pixels for each quadrat
EightMileTest_Quad_totals  <-raster::extract(x=EightMileTest_denom  ,y=EightMileTest_quadrats  ,fun=sum)%>%as.data.frame()%>%'names<-'("Quad Sum")

#####################################Accuracy assesment#################################################
#Reads in Shapefile for quadrat locations (this step is used for accuray assesment)
EightMileTest_quadrats  <- readOGR("Original_data/Headwall","EightMile_TESTQUADS"  )

#Creates object with the total Pixels for each Functional group
EightMileTest_Graminoid_Sedge_sum   <-raster::extract(x=EightMileTest_Graminoid_Sedge   ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Graminoid_Sedge_p"    )
EightMileTest_Lichen_Yellow_sum     <-raster::extract(x=EightMileTest_Lichen_Yellow     ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Lichen_Yellow_p"      )
EightMileTest_Shrub_Other_sum       <-raster::extract(x=EightMileTest_Shrub_Other       ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Shrub_Other_p"        )
EightMileTest_Dwarf_Shrub_Needle_sum<-raster::extract(x=EightMileTest_Dwarf_Shrub_Needle,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Dwarf_Shrub_Needle_p" )
EightMileTest_Dwarf_Shrub_Broad5_sum<-raster::extract(x=EightMileTest_Dwarf_Shrub_Broad5,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Dwarf_Shrub_Broad5_p" )
EightMileTest_Lichen_Dark_sum       <-raster::extract(x=EightMileTest_Lichen_Dark       ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Lichen_Dark_p"        )
EightMileTest_Shrub_Salix_sum       <-raster::extract(x=EightMileTest_Shrub_Salix       ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Shrub_Salix_p"        )
EightMileTest_Forb_sum              <-raster::extract(x=EightMileTest_Forb              ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Forb_p"               )
EightMileTest_Tree_Needle_sum       <-raster::extract(x=EightMileTest_Tree_Needle       ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Tree_Needle_p"        )
EightMileTest_Moss_Pleurocarp_sum   <-raster::extract(x=EightMileTest_Moss_Pleurocarp   ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Moss_Pleurocarp_p"    )
EightMileTest_Shrub_Alder_sum       <-raster::extract(x=EightMileTest_Shrub_Alder       ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Shrub_Alder_p"        )
EightMileTest_Graminoid_Grass_sum   <-raster::extract(x=EightMileTest_Graminoid_Grass   ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Graminoid_Grass_p"    )
EightMileTest_Lichen_Light_sum      <-raster::extract(x=EightMileTest_Lichen_Light      ,y=EightMileTest_quadrats,fun=sum)%>%as.data.frame()%>%'names<-'("Lichen_Light_p"       )
#
#
###Lets combine the datframes created above
EightMileTest_HDW_pixeltotals<-Reduce(cbind,list(EightMileTest_Quad_totals
                                                ,EightMileTest_Graminoid_Sedge_sum   
                                                ,EightMileTest_Lichen_Yellow_sum     
                                                ,EightMileTest_Shrub_Other_sum       
                                                ,EightMileTest_Dwarf_Shrub_Needle_sum
                                                ,EightMileTest_Dwarf_Shrub_Broad5_sum
                                                ,EightMileTest_Lichen_Dark_sum       
                                                ,EightMileTest_Shrub_Salix_sum       
                                                ,EightMileTest_Forb_sum              
                                                ,EightMileTest_Tree_Needle_sum       
                                                ,EightMileTest_Moss_Pleurocarp_sum   
                                                ,EightMileTest_Shrub_Alder_sum       
                                                ,EightMileTest_Graminoid_Grass_sum   
                                                ,EightMileTest_Lichen_Light_sum      ))

###Now we want to calculate the % cover for each Functional group in each quadrat
EightMileTest_HDW_PercentCover<-EightMileTest_HDW_pixeltotals[,2:14]/(EightMileTest_HDW_pixeltotals[,1])*100
#EightMileTest_HDW_PercentCover<-EightMileTest_HDW_PercentCover%>%
#  mutate(CLASS_ID=rownames(EightMileTest_HDW_PercentCover))%>%
#  dplyr::select(CLASS_ID,everything())
#
###Lets merge the metadata with these new dataframes
#EightMileTest_HDW_PercentCover <-merge(EightMileTest_meta,  EightMileTest_HDW_PercentCover  ,by="CLASS_ID")
#EightMileTest_HDW_PercentCover<-EightMileTest_HDW_PercentCover%>%
#  arrange(CLASS_NAME)%>%
#  dplyr::select(-CLASS_CLRS,-CLASS_ID)%>%
#  mutate(CLASS_ID=rownames(EightMileTest_HDW_PercentCover))%>%dplyr::select(CLASS_ID,everything())
#
#write.csv(EightMileTest_HDW_PercentCover ,"Outputs/2_Imagery/Headwall/Prediction/EightMileTest_HDW_PercentCover_TST50.csv")

###save plot as a jpeg
##chm_colors <- c("darkgreen","mediumvioletred","gold","deepskyblue","saddlebrown","orange2","ivory3","darkorange4","khaki1","lightcyan1","mediumorchid3","yellow1","slateblue2")
chm_colors <-distinctColorPalette(nrow(Unique_HDW))
jpeg('Outputs/2_Imagery/Headwall/Prediction/EightMileTest_AccuracyPred50.jpg',width=1200, height=700)
plot(
  EightMileTest_raster,
  legend = FALSE,
  axes=FALSE,
  col = chm_colors[-8],
  box= FALSE,
  xlab="Longitude", 
  ylab="Latitude"
)
plot(EightMileTest_quadrats,border="white",lwd=2,add=TRUE)
legend(
  "right",
  legend = c(paste(Unique_HDW$predicted)),
  fill =chm_colors,
  border = FALSE,
  bty = "n",
  cex=1.5,
  xjust =1,
  horiz = FALSE,
  inset = -0.009,
  par(cex=0.4)
  
)             
dev.off()

#######################Plot without Accuracy assesment##########################
chm_colors <-distinctColorPalette(nrow(Unique_HDW))
jpeg('Outputs/2_Imagery/Headwall/Prediction/EightMileTest_Pred50.jpg',width=1200, height=700)
plot(
  EightMileTest_raster,
  legend = FALSE,
  axes=FALSE,
  col = chm_colors[-8],
  box= FALSE,
  xlab="Longitude", 
  ylab="Latitude"
)
legend(
  "right",
  legend = c(paste(Unique_HDW$predicted)),
  fill =chm_colors,
  border = FALSE,
  bty = "n",
  cex=1.5,
  xjust =1,
  horiz = FALSE,
  inset = -0.009,
  par(cex=0.4)
  
)             
dev.off()

