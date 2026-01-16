computeNonForestedAreaMap <- function(baseLCCMap, pgm){
  nonForestedVegClassesMap <- baseLCCMap
  # Remove forested areas from the WB_NonForestedVegClasses map
  # For now those area do not change, but eventually we will consider areas where
  # biomass is negligible for a long time as non-forested by keeping a history 
  # of total biomass by pixelGroup.
  nonForestedVegClassesMap <- terra::mask(
    nonForestedVegClassesMap, 
    pgm, 
    inverse = TRUE
  )
  # Reassign it names (for nicer plotting) 
  names(nonForestedVegClassesMap) <- "nonForestedVegClasses"
  varnames(nonForestedVegClassesMap) <- "nonForestedVegClasses"
  return (nonForestedVegClassesMap)
}

getWB_NonForestedVegClassesBaseLCCMap <- function(year, cachePath, baseRast){
  lccURL <- paste0("https://opendata.nfis.org/downloads/forest_change/CA_forest_VLCE2_", year, ".zip")
  lccTF <- paste0("CA_forest_VLCE2_", year, ".tif")
  LCCMap <- Cache(
    prepInputs,
    url = lccURL,
    targetFile = lccTF,
    destinationPath = cachePath,
    fun = terra::rast,
    cropTo = baseRast,
    projectTo = baseRast,
    method = "near",
    overwrite = TRUE,
    writeTo = .suffix("rstLCC.tif", paste0("_NTEMS_", year)),
    userTags = c("WB_NonForestedVegClassesBaseLCCMap", "NTEMS", year)
  )
  # Convert to factor and add more descriptive labels
  LCCMap <- terra::as.factor(LCCMap)
  levels(LCCMap) <- data.frame(
    value = c( 20L,        31L,           32L,              33L,         40L,         50L,        80L,          81L,                100L,        210L,             220L,            230L),
    class = c("20-water", "31-snow_ice", "32-rock_rubble", "33-barren", "40-bryoid", "50-shrub", "80-wetland", "81-treed_wetland", "100-herbs", "210-coniferous", "220-broadleaf", "230-mixed_wood")
  )

  # Assign names (for nicer plotting) 
  names(LCCMap) <- "nonForestedVegClasses"
  varnames(LCCMap) <- "nonForestedVegClasses"
  return(LCCMap)
}
