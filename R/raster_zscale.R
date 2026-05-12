#' Approximates the zscale of a raster Digital Elevation Model for 'rayshader'
#'
#' @param raster_input A raster object of elevation data values
#' @param height_units Elevation units of the raster, c("m", "feet")
#'
#' @return a number to be used as zscale in rayshader::plot_3d()
#'
#' @examples
#' raster_zscale(example_raster())
#'
#' @export
# raster_zscale <- function(raster, height_units = "m"){
#
#   raster_wgs84 <- raster::projectRaster(raster, crs = sp::CRS("+proj=longlat +datum=WGS84 +no_defs"))
#
#   scaling <- raster::pointDistance(
#     c(
#       raster::extent(raster_wgs84)@xmin,
#       raster::extent(raster_wgs84)@ymin
#     ),
#     c(raster::extent(raster_wgs84)@xmax,
#       raster::extent(raster_wgs84)@ymin
#     ),
#     lonlat = TRUE
#   ) / ncol(raster_wgs84)
#
#   if(scaling=="feet"){
#     scaling <- scaling * 3.28
#   }
#
#   return(scaling)
#
# }

raster_zscale <- function(raster_input, height_units = "m") {

  # BEFORE: raster::projectRaster(x, crs = sp::CRS(...))
  # AFTER:  terra::project(x, "EPSG:4326") — cleaner EPSG code syntax
  raster_wgs84 <- terra::project(raster_input, "EPSG:4326")
  e            <- terra::ext(raster_wgs84)

  # BEFORE: raster::pointDistance(c(x1,y1), c(x2,y2), lonlat=TRUE)
  # AFTER:  sf::st_distance on two points in WGS84 — returns metres automatically
  p1       <- sf::st_sfc(sf::st_point(c(e$xmin, e$ymin)), crs = 4326)
  p2       <- sf::st_sfc(sf::st_point(c(e$xmax, e$ymin)), crs = 4326)
  width_m  <- as.numeric(sf::st_distance(p1, p2))   # great-circle distance in metres
  scaling  <- width_m / terra::ncol(raster_wgs84)

  if (height_units == "feet") scaling <- scaling * 3.28084

  return(scaling)
}
