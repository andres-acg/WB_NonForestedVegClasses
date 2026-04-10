# WB_NonForestedVegClasses

## Introduction

WB_NonForestedVegClasses is a [SpaDES](https://spades.predictiveecology.org/) module complementing the [LandR](https://landr-manual.predictiveecology.org/) ecosystem of modules for forest biomass and succession simulation. It is part of an ensemble of modules that provide to LandR the statistical prediction of terrestrial lichen biomass from stand type, time-since fire, and terrestrial ecoprovince.

These modules are an implementatiom of [Greuel and Degré-Timmons et al (2021)](https://esajournals-onlinelibrary-wiley-com.acces.bibl.ulaval.ca/doi/full/10.1002/ecs2.3481), developed to support lichen biomass modelling for woodland caribou conservation in the Northwest Territories. The geographical area wherein the model may reasonably be applied should be assessed from Figure 2 of the cited paper. 

The components of the module ensemble are:

- [WB_HartJohnstoneForestClasses](https://github.com/pedrogit/WB_HartJohnstoneForestClasses) - Generates a map classifying LandR forested pixels to 6 (or 7) classes.
- [WB_VegBasedDrainage](https://github.com/pedrogit/WB_VegBasedDrainage) - Generates a map of two drainage classes.
- [WB_NonForestedVegClasses](https://github.com/pedrogit/WB_NonForestedVegClasses) - This module. Generates a map of land cover classes for areas LandR considers to be non-forested.
- [WB_LichenBiomass](https://github.com/pedrogit/WB_LichenBiomass) - Generates a wall-to-wall map of predicted lichen biomass density for forested and non-forested pixels.

These modules are derived from extensive empirical research in the northwest boreal of North America, as described in [Greuel and Degré-Timmons et al (2021)](https://esajournals-onlinelibrary-wiley-com.acces.bibl.ulaval.ca/doi/full/10.1002/ecs2.3481), Casheiro-Guilhem et. al (in prep.) and foundational papers by [Hart and Johnstone et al. (2018)](https://onlinelibrary.wiley.com/doi/abs/10.1111/gcb.14550).

## WB_NonForestedVegClasses Module Overview

The WB_LichenBiomass module compute lichen biomass using two different models: one for forested areas and another one for non-forested areas. The purpose of the WB_NonForestedVegClasses module is to provide WB_LichenBiomass with classified non-forested areas.

At each simulation step, WB_NonForestedVegClasses creates a SpatRaster of non-forested vegetation classes for pixels that, according to LandR, are non-forested by simply setting those pixels to NA. It also set pixels that are outside the study area to NA.

The different classes set in the resulting raster depend on which raster is used as base land cover raster. This base land cover raster is either, in order of preference:

- The same sim$rstLCC SpatRaster instanciated and used by LandR.
- A land cover SpatRaster provided to the module when initiating the simulation.
- The default [NTEMS](https://opendata.nfis.org/mapserver/nfis-change_eng.html) land cover raster.

The module time step would normally be the same 10 year period used by LandR.

WB_NonForestedVegClasses is dynamic because it depends on forest pixel produced by the biomass_core module which is itself dynamic.

### Authors and Citation

* Pierre Racine <pierre.racine@sbf.ulaval.ca> [aut, cre]
* Andres Caseiro Guilhem <andres.caseiro-guilhem.1@ulaval.ca> [aut]
* Steven G. Cumming <stevec.boreal@gmail.com> [aut]

Racine, P., Caseiro Guilhem, A., Cumming, S.G. (2026) *WB_NonForestedVegClasses: A SpaDES module to determine non-forested areas in western boreal forests of Canada.* SpaDES Module.

### Module Parameters

| Parameter | Class | Default | Description |
| --- | --- | --- | --- |
| WB_NonForestedVegClassesTimeStep | integer | 10 | Module return interval, at which the SpatRaster is regenerated. |
| baseLCCYear | integer | 2010 | Year of the NTEMS land cover raster to download if no other land cover raster is used. |


### Expected Module Inputs

| Input Object | Class | Description |
| --- | --- | --- |
| pixelGroupMap | SpatRast | Forested area as defined by the pixelGroupMap raster produced by the Biomass_core module or an equivalent raster. |
| rasterToMatch | SpatRast | Study area as defined by the rasterToMatch raster used by the Biomass_core module or an equivalent raster. |
| WB_NonForestedVegClassesBaseLCCMap | SpatRast | Base land cover raster. Default to either sim$rstLCC or the downloaded NTEMS raster if not provided at simulation initiation with simInit(). |

### Module Outputs

| Output Object | Class | Description |
| --- | --- | --- |
| WB_NonForestedVegClassesMap | SpatRast | Raster map classified into different classes. |

### Code

The code is available here: https://github.com/pedrogit/WB_NonForestedVegClasses

### Minimal Self Contained Workflow Example

Soon...



