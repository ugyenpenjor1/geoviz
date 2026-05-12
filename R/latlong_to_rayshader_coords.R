#' Converts WGS84 lat long points into 'rayshader' coordinates. Useful for adding arbitrary points and text to a 'rayshader' scene.
#'
#' @param raster_input a raster
#' @param lat vector of WGS84 latitude points
#' @param long vector of WGS84 longitude points
#'
#' @return A tibble with x,y in 'rayshader' coordinates
#'
#' @examples
#' latlong_to_rayshader_coords(example_raster(), example_igc()$lat, example_igc()$long)
#' @export
# latlong_to_rayshader_coords <- function(raster_input, lat, long){
#
#   #Convert the track to spatialpoints in raster_input's projection
#   track <- sf::st_as_sf(
#     data.frame(x = long, y = lat),
#     coords = c("x", "y"),
#     crs    = 4326
#   )
#   track <- sf::st_transform(track, crs = sf::st_crs(raster::crs(raster_input)))
#
#   track <- tibble::as_tibble(sf::st_coordinates(track))
#
#   lat <- track$lat
#
#   long <- track$long
#
#   #Work out the dimensions of raster_input and map the track onto it
#   e <- raster::extent(raster_input)
#
#   cell_size_x <- raster::pointDistance(c(e@xmin, e@ymin),
#                                        c(e@xmax, e@ymin), lonlat = FALSE)/ncol(raster_input)
#
#   cell_size_y <- raster::pointDistance(c(e@xmin, e@ymin),
#                                        c(e@xmin, e@ymax), lonlat = FALSE)/nrow(raster_input)
#
#   distances_x <- raster::pointDistance(c(e@xmin, e@ymin),
#                                        cbind(long, rep(e@ymin, length(long))), lonlat = FALSE)/cell_size_x - (e@xmax - e@xmin)/2/cell_size_x
#
#   distances_y <- raster::pointDistance(c(e@xmin, e@ymin),
#                                        cbind(rep(e@xmin, length(lat)), lat), lonlat = FALSE)/cell_size_y - (e@ymax - e@ymin)/2/cell_size_y
#
#   tibble::tibble(x = distances_x,
#          y = distances_y)
#
# }

latlong_to_rayshader_coords <- function(raster_input, lat, long) {

  # BEFORE: sp::SpatialPoints + sp::spTransform
  # AFTER:  sf::st_as_sf + sf::st_transform
  track <- sf::st_as_sf(
    data.frame(x = long, y = lat),
    coords = c("x", "y"),
    crs    = 4326
  )
  track <- sf::st_transform(track, crs = sf::st_crs(terra::crs(raster_input)))

  # IMPORTANT: sf::st_coordinates returns columns named X and Y (uppercase)
  # NOT lat/long — this was a silent bug in the original code
  coords    <- sf::st_coordinates(track)
  long_proj <- coords[, "X"]   # projected Easting
  lat_proj  <- coords[, "Y"]   # projected Northing

  # Raster extent and cell sizes — terra::ext replaces raster::extent
  e           <- terra::ext(raster_input)
  cell_size_x <- (e$xmax - e$xmin) / terra::ncol(raster_input)
  cell_size_y <- (e$ymax - e$ymin) / terra::nrow(raster_input)

  # Convert projected coords to rayshader scene units (centred on 0,0)
  # Replaces raster::pointDistance — in a projected CRS, distance is simple arithmetic
  distances_x <- (long_proj - e$xmin) / cell_size_x -
    (e$xmax - e$xmin) / 2 / cell_size_x
  distances_y <- (lat_proj  - e$ymin) / cell_size_y -
    (e$ymax - e$ymin) / 2 / cell_size_y

  tibble::tibble(x = distances_x, y = distances_y)
}
