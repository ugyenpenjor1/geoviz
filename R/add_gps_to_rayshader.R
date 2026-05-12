#' Adds a GPS trace to a 'rayshader' scene
#'
#' @param raster_input a raster
#' @param lat vector of decimal latitude points
#' @param long vector of decimal longitude points
#' @param alt vector of altitudes
#' @param zscale ratio of raster cells to altitude
#' @param line_width line width of the gps trace
#' @param colour colour of the gps trace
#' @param alpha alpha of the gps trace (has no effect if lightsaber = TRUE)
#' @param lightsaber (default = TRUE) gives the GPS trace an inner glow affect
#' @param clamp_to_ground (default = FALSE) clamps the gps trace to ground level + raise_agl
#' @param raise_agl (default = 0) raises a clamped to ground track by the specified amount. Useful if gps track occasionally disappears into the ground.
#' @param ground_shadow (default = FALSE) adds a ground shadow to a flight gps trace
#' @param as_line (default = TRUE) Set to FALSE to render single points instead of a trace line (which then ignores line_width & lightsaber)
#' @param point_size size of points when as_line = TRUE
#'
#' @return Adds GPS trace to the current 'rayshader' scene
#'
#' @examples
#' flight <- example_igc()
#' add_gps_to_rayshader(example_raster(),
#'   flight$lat,
#'   flight$long,
#'   flight$altitude,
#'   zscale = 25)
#'
#' @export
# add_gps_to_rayshader <- function(raster_input, lat, long, alt, zscale, line_width = 1, colour = "red", alpha = 0.8, lightsaber = TRUE, clamp_to_ground = FALSE, raise_agl = 0, ground_shadow = FALSE, as_line = TRUE, point_size = 20){
#
#   coords <- latlong_to_rayshader_coords(raster_input, lat, long)
#
#   distances_x <- coords$x
#
#   distances_y <- coords$y
#
#
#   if (clamp_to_ground | ground_shadow) {
#
#     sp_gps <- sf::st_as_sf(
#       data.frame(x = long, y = lat),
#       coords = c("x", "y"),
#       crs    = 4326
#     )
#     sp_gps <- sf::st_transform(sp_gps, crs = sf::st_crs(raster::crs(raster_input)))
#     sp_gps <- sf::st_coordinates(sp_gps)   # extract coords back as matrix if needed downstream
#
#     gps_ground_line <- raster::extract(raster_input, sp_gps)
#
#   }
#
#   if(clamp_to_ground){
#
#     track_altitude <- gps_ground_line
#
#   } else {
#
#     track_altitude <- alt
#   }
#
#   if(as_line){
#
#     if(!lightsaber){
#       rgl::lines3d(
#         distances_x,  #lat
#         track_altitude / zscale,  #alt
#         -distances_y,  #long
#         color = colour,
#         alpha = alpha,
#         lwd = line_width
#       )
#     } else {
#
#       #render track 3 times with transparent & thicker outside
#
#       rgl::lines3d(
#         distances_x,
#         track_altitude / zscale,
#         -distances_y,
#         color = colour,
#         alpha = 0.2,
#         lwd = line_width * 6,
#         shininess = 25,
#         fog = TRUE
#       )
#
#       rgl::lines3d(
#         distances_x,
#         track_altitude / zscale,
#         -distances_y,
#         color = colour,
#         alpha = 0.6,
#         lwd = line_width * 3,
#         shininess = 80,
#         fog = TRUE
#       )
#
#       rgl::lines3d(
#         distances_x,
#         track_altitude / zscale,
#         -distances_y,
#         color = lighten(colour),
#         alpha = 1,
#         lwd = 1,
#         shininess = 120
#       )
#
#     }
#
#     if(ground_shadow){
#       rgl::lines3d(
#         distances_x,
#         gps_ground_line / zscale + raise_agl,
#         -distances_y,
#         color = "black",
#         alpha = 0.4,
#         lwd = line_width * 2,
#         shininess = 25,
#         fog = TRUE
#       )
#     }
#   } else {
#
#     rgl::points3d(
#       distances_x,  #lat
#       track_altitude / zscale,  #alt
#       -distances_y,  #long
#       color = colour,
#       alpha = alpha,
#       size = point_size
#     )
#   }
# }

add_gps_to_rayshader <- function(raster_input, lat, long, alt, zscale,
                                 line_width = 1, colour = "red", alpha = 0.8,
                                 lightsaber = TRUE, clamp_to_ground = FALSE,
                                 raise_agl = 0, ground_shadow = FALSE,
                                 as_line = TRUE, point_size = 20) {

  coords      <- latlong_to_rayshader_coords(raster_input, lat, long)
  distances_x <- coords$x
  distances_y <- coords$y

  if (clamp_to_ground || ground_shadow) {

    # BEFORE: sp::SpatialPoints + sp::spTransform + raster::extract
    # AFTER:  sf::st_as_sf + sf::st_transform + terra::extract
    gps_sf <- sf::st_as_sf(
      data.frame(x = long, y = lat),
      coords = c("x", "y"),
      crs    = 4326
    )
    gps_sf <- sf::st_transform(gps_sf, crs = sf::st_crs(terra::crs(raster_input)))

    # sf::st_coordinates returns matrix with columns X, Y (uppercase)
    # terra::extract accepts a two-column coordinate matrix directly
    gps_coords      <- sf::st_coordinates(gps_sf)         # [n × 2]: X, Y
    gps_ground_line <- terra::extract(raster_input, gps_coords)[, 2]
  }

  track_altitude <- if (clamp_to_ground) gps_ground_line else alt

  if (as_line) {

    if (!lightsaber) {
      rgl::lines3d(distances_x, track_altitude / zscale, -distances_y,
                   color = colour, alpha = alpha, lwd = line_width)
    } else {
      # Three-pass glowing lightsaber effect
      rgl::lines3d(distances_x, track_altitude / zscale, -distances_y,
                   color = colour, alpha = 0.2, lwd = line_width * 6,
                   shininess = 25, fog = TRUE)
      rgl::lines3d(distances_x, track_altitude / zscale, -distances_y,
                   color = colour, alpha = 0.6, lwd = line_width * 3,
                   shininess = 80, fog = TRUE)
      rgl::lines3d(distances_x, track_altitude / zscale, -distances_y,
                   color = lighten(colour), alpha = 1, lwd = 1, shininess = 120)
    }

    if (ground_shadow) {
      rgl::lines3d(distances_x, gps_ground_line / zscale + raise_agl, -distances_y,
                   color = "black", alpha = 0.4, lwd = line_width * 2,
                   shininess = 25, fog = TRUE)
    }

  } else {
    rgl::points3d(distances_x, track_altitude / zscale, -distances_y,
                  color = colour, alpha = alpha, size = point_size)
  }
}

