##Creates a spectral library from spectroradiometeric scans based on Landsat bandpasses
library(spectrolab)
library(tidyverse)

##Reads in spectral library as a spectral object
##This is the spectral library that had all uncalibrated scans removed
alaskaSpeclib<-readRDS("Outputs/1_Field_spec/1_Processing/PSR_data/PSR_ProcessedSpec/alaskaSpecLib_reduced.rds")

##Lets create an object of bandpasses from imagery
#We'll want the average of these bandpasses
band1<-mean(0.45:0.52)*1000
band2<-mean(0.52:0.60)*1000
band3<-mean(0.63:0.69)*1000
band4<-mean(0.77:0.90)*1000
band5<-mean(1.55:1.75)*1000
band7<-mean(2.09:2.35)*1000

Landsat_wv<-c( band1
              ,band2
              ,band3
              ,band4
              ,band5
              ,band7)

###Now we want to resample alsakSpeclib based on the band passes
alaskaSpeclib_LAN<-spectrolab::resample(alaskaSpeclib,Landsat_wv)

###Lets convert our new spectral library spectral object  to a dataframe
##Run logical test to see if this conversion affect reflectance values
##Are there values outside of the rane 0-2???
alaskaSpecLib_test<-alaskaSpeclib_LAN%>%as.data.frame()%>%dplyr::select(-sample_name)

####Lets run that test again
tst2<-lapply(alaskaSpecLib_test[-1:-9],range)%>%as.data.frame%>%t()%>%as.data.frame
tst2$V1%>%range()##There are negative values being created here, this is where the problem lies, how can we solve this???
tst2$V2%>%range()##There are no weird values, those are values outside of 0 and 2

##Now lets convert to a spectral object and add metadata
alaskaSpecLib_LAN<-alaskaSpecLib_test[-1:-9]%>%as.spectra()
meta(alaskaSpecLib_LAN)<-data.frame(alaskaSpecLib_test[1:9], stringsAsFactors = FALSE)

##Lets add metadata to the dataset to be used in models later 
##Metadata contains l8 categories
##Firts we want to read in the meatdata that will be used
veg_RefDf    <-read.csv("Outputs/1_Field_spec/1_Processing/Landsat_data/Veg_ref.csv")
Lichen_groups<-read.csv("Outputs/1_Field_spec/1_Processing/PSR_data/PSR_ProcessedSpec/Lichen_groups.csv")

##Now lets do a inner_join
Lichen_groups2<-inner_join (Lichen_groups ,veg_RefDf, by = "PFT")
Lichen_groups3<-inner_join(alaskaSpecLib_test,Lichen_groups2[,c("PFT","PFT_2","PFT_3","color")], 
                           by = c("PFT","PFT_2","PFT_3"))%>%
  dplyr::select(ScanID,PFT,PFT_2,PFT_3,PFT_4,color,everything())

##ahnge column name color to color_l8
colnames(Lichen_groups3)[6]<-"color_l8"

##lets create a dataframe wih a count of all the color groups
Lichen_groups_count<-table(Lichen_groups3$color)%>%as.data.frame()
colnames(Lichen_groups_count)[1]<-"colourGroup_1"

##Lets add other columns with more course colour groups
##Lets add color group l4
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="black"]    <-"dark"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="brown"]    <-"dark"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="gray"]     <-"dark"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="green"]    <-"dark"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="greengray"]<-"dark"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="orange"]   <-"light"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="white"]    <-"light"
Lichen_groups3$color_l4[Lichen_groups3$color_l8=="yellow"]   <-"yellow"

##Lets add color group l3
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="black"]    <-"dark"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="brown"]    <-"dark"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="gray"]     <-"dark"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="green"]    <-"dark"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="greengray"]<-"dark"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="orange"]   <-"light"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="white"]    <-"light"
Lichen_groups3$color_l3[Lichen_groups3$color_l8=="yellow"]   <-"light"

##Lets rearrange columns
Lichen_groups3<-Lichen_groups3%>%
  dplyr::select(ScanID,PFT,PFT_2,PFT_3,PFT_4,color_l8,color_l4,color_l3,everything())

##Lets save our bandpasses and other outputs
write(Landsat_wv,"Outputs/1_Field_spec/1_Processing/Landsat_data/Landsat_wv")
write.csv(alaskaSpecLib_test        ,"Outputs/1_Field_spec/1_Processing/Landsat_data/alaskaSpecLib_LAN_df.csv"        ,row.names = FALSE)
write.csv(Lichen_groups3            ,"Outputs/1_Field_spec/1_Processing/Landsat_data/Lichen_groups_df.csv"            ,row.names = FALSE)
write.csv(Lichen_groups_count       ,"Outputs/1_Field_spec/1_Processing/Landsat_data/Lichen_groups_count.csv"         ,row.names = FALSE)

##Now lets save our New headwall spectral library
saveRDS(alaskaSpecLib_LAN,"Outputs/1_Field_spec/1_Processing/Landsat_data/alaskaSpeclib_LAN.rds")



