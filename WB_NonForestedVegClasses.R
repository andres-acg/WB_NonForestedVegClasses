defineModule(sim, list(
  name = "WB_NonForestedVegClasses",
  description = paste("Create a map of non-forested areas based on forested areas and a land cover product."),
  keywords = c("non-forested area", "western boreal"),
  authors =  c(
    person("Pierre", "Racine", email= "pierre.racine@sbf.ulaval.ca", role = "aut")
  ),
  childModules = character(0),
  version = list(WB_NonForestedVegClasses = "0.0.0.2"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  # citation = list("citation.bib"),
  # documentation = list("NEWS.md", "README.md", "WB_LichenBiomass.Rmd"),
  reqdPkgs = list("reproducible", "terra", "LandR"),
  loadOrder = list(after = c("Biomass_core")),
  parameters = rbind(
    defineParameter("WB_NonForestedVegClassesTimeStep", "numeric", 1, NA, NA,
                    "Simulation time at which the non-forested map is regenerated."),
    defineParameter("baseLCCYear", "numeric", 2020, NA, NA,
                    paste("Year of the SCANFI land cover map fetched as a LAST-RESORT",
                          "fallback for WB_NonForestedVegClassesBaseLCCMap -- only used",
                          "when neither WB_NonForestedVegClassesBaseLCCMap NOR sim$rstLCC",
                          "is available (e.g. running this module standalone). In the",
                          "normal case, sim$rstLCC (SCANFI for the simulation year,",
                          "produced upstream by Biomass_borealDataPrep) is reused directly",
                          "and this parameter is ignored. Must be one of the SCANFI V2",
                          "years: 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025."))
  ),
  inputObjects = rbind(
    expectsInput(objectName = "pixelGroupMap",
                 objectClass = "SpatRaster",
                 desc = paste("pixelGroupMap from the ",
                              "biomass_core module used to determine ",
                              "forested areas"),
                 sourceURL = NA),
    expectsInput(objectName = "rasterToMatch",
                 objectClass = "SpatRaster",
                 desc = "A raster version of the `studyArea`"),
    expectsInput(objectName = "rstLCC",
                 objectClass = "SpatRaster",
                 desc = paste("This run's own SCANFI land cover map, normally produced",
                              "upstream by Biomass_borealDataPrep for the simulation year.",
                              "When present, it is reused directly as",
                              "WB_NonForestedVegClassesBaseLCCMap -- avoids a second land",
                              "cover download for the same year/product. Optional: declaring",
                              "it here only tells SpaDES to run Biomass_borealDataPrep's",
                              ".inputObjects() first; a SCANFI fallback fetch (keyed on",
                              "baseLCCYear) runs if it is genuinely absent."),
                 sourceURL = NA),
    expectsInput(objectName = "WB_NonForestedVegClassesBaseLCCMap",
                 objectClass = "SpatRaster",
                 desc = "",
                 sourceURL = "")
  ),
  outputObjects = rbind(
    createsOutput(objectName = "WB_NonForestedVegClassesMap", 
                  objectClass = "SpatRaster", 
                  desc = "Raster of classified non-forested areas.")
  )
))

doEvent.WB_NonForestedVegClasses = function(sim, eventTime, eventType) {
  switch(
    eventType,
    
    init = {
      sim <- Init(sim)
      sim <- scheduleEvent(sim, time(sim), "WB_NonForestedVegClasses", "reComputeNonForestedAreaMap", 2)
    },
    
    reComputeNonForestedAreaMap = {
      sim <- reComputeNonForestedAreaMap(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$WB_NonForestedVegClassesTimeStep, "WB_NonForestedVegClasses", "reComputeNonForestedAreaMap")
    },
    warning(noEventWarning(sim))
  )
  return(invisible(sim))
}


Init <- function(sim){

  # If WB_NonForestedVegClassesBaseLCCMap is not provided in the objects, make it a copy of sim$rstLCC
  # if (!suppliedElsewhere("WB_NonForestedVegClassesBaseLCCMap", sim) && !is.null(sim$rstLCC)){
  #   sim$WB_NonForestedVegClassesBaseLCCMap <- sim$rstLCC
  #
  #   # Reclass any disturbed values assigned by prepInputs_NTEMS_LCC_FAO() (240) to shrub (50)
  #   sim$WB_NonForestedVegClassesBaseLCCMap[sim$WB_NonForestedVegClassesBaseLCCMap == 240] <- 50
  # }
  # Project, crop and mask the base LCC map to rasterToMatch
  # This is done only once wherever the LCC was instanciated from (default, rstLCC or simInit)
  if (!.compareRas(sim$WB_NonForestedVegClassesBaseLCCMap, sim$rasterToMatch, stopOnError = FALSE)) {

    sim$WB_NonForestedVegClassesBaseLCCMap <- postProcess(
      sim$WB_NonForestedVegClassesBaseLCCMap,
      projectTo = sim$rasterToMatch,
      method = "mode",
      cropTo = sim$rasterToMatch,
      maskTo = sim$rasterToMatch
    )
  }

  return(invisible(sim))
}

reComputeNonForestedAreaMap <- function(sim) {
  message("Recomputing sim$WB_NonForestedVegClassesMap...")

  # Simply remove forested areas from the base LCC map
  sim$WB_NonForestedVegClassesMap <- computeNonForestedAreaMap(
    sim$WB_NonForestedVegClassesBaseLCCMap,
    sim$pixelGroupMap
  )

  return(invisible(sim))
}

.inputObjects <- function(sim) {
  userTags <- c(currentModule(sim), "function:.inputObjects")
  ##############################################################################
  # Create a dummy pixelGroupMap if none is provided
  ##############################################################################
  if(!suppliedElsewhere("pixelGroupMap", sim)){
    nbGroup <- 200
    pixelGroupRastWidth <- 1000
    message("##############################################################################")
    message("pixelGrouMap not supplied.")
    message("Please provide one. Creating random map ", pixelGroupRastWidth, " pixels by ",
            pixelGroupRastWidth, " pixels with ", nbGroup, " groups...")

    sim$pixelGroupMap <- Cache(
      getRandomCategoricalMap,
      origin = c(-667296, 1758502),
      ncol = pixelGroupRastWidth,
      nrow = pixelGroupRastWidth,
      crs = "ESRI:102002",
      nbregion = nbGroup,
      seed = 100,
      userTags = c(userTags, "WB_pixelGroupMap"),
      omitArgs = c("userTags")
    )
  }

  ##############################################################################
  # rasterToMatch must be provided by some module (normally Biomass_core)
  ##############################################################################
  if (!suppliedElsewhere("rasterToMatch", sim)) {
    needRTM <- TRUE
    message("There is no rasterToMatch supplied; will attempt to use rawBiomassMap")
  }

  ##############################################################################
  # Determine the base raster to use for cropping, masking and projecting the LCC 
  # map. This will be either pixelGroupMap or rasterToMatch, depending on which 
  # one is supplied. If both are supplied, pixelGroupMap will be used.
  ##############################################################################
  if (!is.null(sim$pixelGroupMap)){
    baseRast <- sim$pixelGroupMap
  }
  else if (!is.null(sim$rasterToMatch)){
    baseRast <- sim$rasterToMatch
  }
  else {
    stop(paste("At least one of pixelGroupMap or rasterToMatch must be defined ",
               "in sim before WB_NonForestedVegClasses can be initialized..."))
  }
  ##############################################################################
  # Base land cover map -- SCANFI everywhere now, no NTEMS VLCE2.
  #
  # Preferred path: reuse sim$rstLCC. It is normally produced upstream by
  # Biomass_borealDataPrep (SCANFI for THIS simulation year, FAO-disturbed
  # pixels already coded 240) -- reusing it costs nothing extra, no second
  # land cover download for the same year/product.
  #
  # Fallback path (only when rstLCC genuinely is not available, e.g. this
  # module is run standalone without Biomass_borealDataPrep): fetch SCANFI
  # directly for `baseLCCYear`.
  ##############################################################################
  if (!suppliedElsewhere("WB_NonForestedVegClassesBaseLCCMap", sim)) {
    if (!is.null(sim$rstLCC)) {
      message("##############################################################################")
      message("Using sim$rstLCC as WB_NonForestedVegClassesBaseLCCMap (SCANFI, already ",
              "prepared upstream for this run) -- no extra land cover download.")

      lcc <- terra::deepcopy(sim$rstLCC)
      try(terra::levels(lcc) <- NULL, silent = TRUE)
      try(terra::coltab(lcc) <- NULL, silent = TRUE)
      lcc[lcc == 240] <- 50   # FAO-disturbed -> shrub, same rule used everywhere else
      sim$WB_NonForestedVegClassesBaseLCCMap <- addSCANFI_LCC_Legend(lcc)

    } else {
      message("##############################################################################")
      message("Neither sim$rstLCC, nor WB_NonForestedVegClassesBaseLCCMap were supplied.")
      message("Fetching SCANFI land cover for year ", P(sim)$baseLCCYear,
              " directly (fallback path; this normally only happens when running ",
              "WB_NonForestedVegClasses standalone, without Biomass_borealDataPrep)...")

      sim$WB_NonForestedVegClassesBaseLCCMap <- getWB_NonForestedVegClassesBaseLCCMap_SCANFI(
        P(sim)$baseLCCYear,
        getPaths()$inputPath,
        baseRast
      )
    }
  }

  return(invisible(sim))
}
