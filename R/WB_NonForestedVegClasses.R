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

## SCANFI / FAO land cover code legend. Kept in sync BY HAND with
## SCANFI_LCC_DICT in modules/WB_LichenBiomass/R/meanBiomassTable.R -- the two
## can't literally share code because SpaDES modules each source only their
## own R/ folder. 240 (FAO-disturbed) is deliberately absent: every map this
## legend gets attached to has already had 240 reclassed to 50 (shrub).
addSCANFI_LCC_Legend <- function(lcc) {
  lcc <- terra::as.factor(lcc)
  terra::levels(lcc) <- data.frame(
    value = c(0L, 20L, 31L, 32L, 33L, 40L, 50L, 80L, 81L, 100L, 210L, 220L, 230L),
    class = c("0-unclassified", "20-water", "31-snow_ice", "32-rock_rubble",
              "33-exposed_barren_land", "40-bryoids", "50-shrubs", "80-wetland",
              "81-wetland_treed", "100-herbs", "210-coniferous", "220-broadleaf",
              "230-mixedwood")
  )
  names(lcc) <- "nonForestedVegClasses"
  varnames(lcc) <- "nonForestedVegClasses"
  lcc
}

## Fallback ONLY: used when sim$rstLCC is not available at all (e.g. this
## module run standalone, without Biomass_borealDataPrep upstream). The normal
## path in .inputObjects() reuses sim$rstLCC directly and never calls this.
getWB_NonForestedVegClassesBaseLCCMap_SCANFI <- function(year, inputPath, baseRast){
  lcc <- LandR::prepInputs_SCANFI_LCC_FAO(
    year            = year,
    dataVersion     = "V2",
    disturbedCode   = 240,
    destinationPath = inputPath,
    cropTo          = baseRast,
    maskTo          = baseRast,
    projectTo       = baseRast,
    resampleMethod  = "near"
  )
  lcc[lcc == 240] <- 50   # FAO-disturbed -> shrub, same rule used everywhere else
  addSCANFI_LCC_Legend(lcc)
}
