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

## SCANFI land cover code legend. Kept in sync BY HAND with SCANFI_LCC_DICT in
## modules/WB_LichenBiomass/R/meanBiomassTable.R -- the two can't literally
## share code because SpaDES modules each source only their own R/ folder.
##
## These are SCANFI's OWN eight nfiLandCover classes, expressed in Canada LCC
## codes by the data producer (the downloaded file is named
## SCANFI_att_nfiLandcover_CanadaLCCclassCodes_<year>_v2_*.tif). The former
## NTEMS VLCE2 legend used here listed 31/32/33 (snow-ice, rock-rubble,
## exposed-barren) and 80/81 (wetland, wetland-treed) -- none of which SCANFI
## emits -- while omitting 30, SCANFI's single Rock/barren class, which is
## present in the data. Any class missing from this table is dropped to NA when
## the categories are attached, so the omission of 30 was not cosmetic.
##
## SCANFI has NO wetland class: wetland pixels fall into shrub/herb/coniferous.
## 0 is retained only as a nodata/unclassified safety net.
## 240 (FAO-disturbed) is deliberately absent: every map this legend gets
## attached to has already had 240 reclassed to 50 (shrub).
addSCANFI_LCC_Legend <- function(lcc) {
  lcc <- terra::as.factor(lcc)
  # NOTE: must use the bare `levels<-` generic here, NOT `terra::levels<-`.
  # terra implements this replacement method via S4 setMethod() on the base
  # generic rather than exporting a standalone "levels<-" object, so
  # `terra::levels(lcc) <- value` fails with "'levels<-' is not an exported
  # object from 'namespace:terra'". The bare form dispatches correctly via
  # S4 method resolution as long as terra is loaded (it always is here).
  levels(lcc) <- data.frame(
    value = c(0L, 20L, 30L, 40L, 50L, 100L, 210L, 220L, 230L),
    class = c("0-unclassified", "20-water", "30-rock", "40-bryoids",
              "50-shrubs", "100-herbs", "210-coniferous", "220-broadleaf",
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
