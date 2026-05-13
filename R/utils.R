# square_bounding_box <- function(lat, long, square_km){
#   #create point
#   bounding_box <- sp::SpatialPoints(cbind(long, lat, square_km), proj4string = sp::CRS("+proj=longlat +datum=WGS84 +no_defs"))
#
#   #Round target lat long to use to use as centre for equal area projection
#   lat_round <- round(lat, 0)
#   long_round <- round(long, 0)
#
#   #Transform to be able to buffer
#   bounding_box <-
#     sp::spTransform(bounding_box, sp::CRS(paste0("+proj=laea +lat_0=", lat_round,
#                                                  " +lon_0=", long_round,
#                                                  " +x_0=4321000 +y_0=3210000 +ellps=GRS80 ",
#                                                  "+towgs84=0,0,0,0,0,0,0 +units=m +no_defs")))
#
#   #create buffer square
#   bounding_shape <- sf::st_buffer(bounding_box, dist = bounding_box$square_km * 1000, nQuadSegs=1, endCapStyle="SQUARE")
#
#   return(bounding_shape)
# }
#
# track_bounding_box <- function(lat_points, long_points, width_buffer){
#
#   #Error: package rgdal is required for spTransform methods
#   #rgdal added to Imports and called here to pass checks
#   #temp_rgdal <- rgdal::getGDALCheckVersion()
#   temp_rgdal <- sf::sf_extSoftVersion()
#
#   #Make a bounding box around the track points
#   bounding_box <- sp::SpatialPoints(cbind(long_points, lat_points),
#                                     proj4string = sp::CRS("+proj=longlat +datum=WGS84 +no_defs"))
#
#   bounding_box <- methods::as(raster::extent(bounding_box), 'SpatialPolygons')
#
#   sp::proj4string(bounding_box) <- "+proj=longlat +datum=WGS84 +no_defs"
#
#   #Reproject for sf
#   bounding_box <- sp::spTransform(bounding_box, sp::CRS("+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))
#
#   #Pad a border around the bounding box
#   bounding_shape <- sf::st_buffer(bounding_box, endCapStyle = "SQUARE", dist = width_buffer * 1000)
#
#   return(bounding_shape)
#
# }

###############

# square_bounding_box <- function(lat, long, square_km) {
#
#   # Create point as sf object
#   point_sf <- sf::st_sfc(
#     sf::st_point(c(long, lat)),
#     crs = 4326
#   )
#
#   # Project to local equal-area CRS (centred on the point for accuracy)
#   lat_round  <- round(lat, 0)
#   long_round <- round(long, 0)
#   local_crs  <- paste0("+proj=laea +lat_0=", lat_round,
#                        " +lon_0=", long_round,
#                        " +x_0=4321000 +y_0=3210000 +ellps=GRS80 ",
#                        "+towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
#
#   point_proj <- sf::st_transform(point_sf, crs = sf::st_crs(local_crs))
#
#   # Buffer as a square (nQuadSegs=1 + SQUARE = square shape)
#   bounding_shape <- sf::st_buffer(
#     point_proj,
#     dist        = square_km * 1000,
#     nQuadSegs   = 1,
#     endCapStyle = "SQUARE"
#   )
#
#   return(bounding_shape)
# }
#
#
# track_bounding_box <- function(lat_points, long_points, width_buffer) {
#
#   # Create sf points object from coordinates
#   points_sf <- sf::st_as_sf(
#     data.frame(x = long_points, y = lat_points),
#     coords = c("x", "y"),
#     crs    = 4326
#   )
#
#   # Bounding box → polygon in WGS84
#   bbox_poly <- sf::st_as_sfc(sf::st_bbox(points_sf))
#
#   # Project to equal-area CRS for accurate buffering
#   local_crs  <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
#   bbox_proj  <- sf::st_transform(bbox_poly, crs = sf::st_crs(local_crs))
#
#   # Buffer with square end caps
#   bounding_shape <- sf::st_buffer(
#     bbox_proj,
#     dist        = width_buffer * 1000,
#     endCapStyle = "SQUARE"
#   )
#
#   return(bounding_shape)
# }

###############

# rescale <- function (x, nx1, nx2, minx, maxx){
#   nx = nx1 + (nx2 - nx1) * (x - minx)/(maxx - minx)
#   return(nx)
# }
#
# lighten <- function(color, factor=0.2){
#   col <- grDevices::col2rgb(color)
#   col <- col+ (255 - col) * factor
#   col <- grDevices::rgb(t(col), maxColorValue=255)
#   col
# }
#
#
# compose_tile_grid <- function (tile_grid, images)
# {
#   #Adapted from slippymath to cope with 8 bit png images (1 layer). Slippymath saves them as .jpg but they aren't
#   bricks <- purrr::pmap(.l = list(x = tile_grid$tiles$x, y = tile_grid$tiles$y,
#                                   image = images), .f = function(x, y, image, zoom) {
#                                     bbox <- slippymath::tile_bbox(x, y, zoom)
#
#                                     raster_img <- raster::brick(image, crs = attr(bbox,
#                                                                                   "crs")$proj4string)
#                                     #adaptation --------------------
#                                     if (dim(raster_img)[3]==1){ #tile_raster has one layer
#                                       raster_img <- raster::raster(image, crs = attr(bbox,
#                                                                                      "crs")$proj4string)
#
#                                       #Apply the raster's colortable to create a 3 layer rgb version
#                                       raster_img <- raster::setValues(raster::brick(raster_img, raster_img, raster_img),
#                                                           t(grDevices::col2rgb(raster_img@legend@colortable))[raster::values(raster_img) + 1,])
#                                     }
#                                     #-------------------------------
#
#                                     raster::extent(raster_img) <- raster::extent(bbox[c("xmin",
#                                                                                         "xmax", "ymin", "ymax")])
#                                     raster_img
#                                   }, zoom = tile_grid$zoom)
#   geo_refd_raster <- do.call(raster::merge, bricks)
#   geo_refd_raster
# }
#
#
# raster_to_png <- function(tile_raster, file_path)
# {
#
#   #Adapted from slippymath to fix margin problem
#   tile_raster@data@values <- sweep(tile_raster@data@values,
#                                    MARGIN = 2, STATS = tile_raster@data@max, FUN = "/")
#
#   png::writePNG(raster::as.array(tile_raster), target = file_path)
#
# }

################################################################################


# Rescale x from [minx, maxx] to [nx1, nx2] - unchanged
rescale <- function(x, nx1, nx2, minx, maxx) {
  nx1 + (nx2 - nx1) * (x - minx) / (maxx - minx)
}

# Lighten a colour toward white - unchanged
lighten <- function(color, factor = 0.2) {
  col <- grDevices::col2rgb(color)
  col <- col + (255 - col) * factor
  grDevices::rgb(t(col), maxColorValue = 255)
}

# REPLACES sp::char2dms + methods::as(..., "numeric")
# Parses IGC DMS string format ("DDdMM.mmm'H") to decimal degrees
# Called only by read_igc() - no other dependency on sp needed
igc_dms_to_decimal <- function(dms_vec) {
  sapply(dms_vec, function(dms) {
    hemisphere <- substr(dms, nchar(dms), nchar(dms))     # final char: N/S/E/W
    body <- substr(dms, 1, nchar(dms) - 1)          # strip hemisphere
    parts <- strsplit(body, "[d']")[[1]]             # split on 'd' and "'"
    degrees <- as.numeric(parts[1])
    minutes <- as.numeric(parts[2])
    decimal <- degrees + minutes / 60
    if (hemisphere %in% c("S", "W")) decimal <- -decimal
    decimal
  }, USE.NAMES = FALSE)
}


square_bounding_box <- function(lat, long, square_km) {

  point_sf <- sf::st_sfc(sf::st_point(c(long, lat)), crs = 4326)

  lat_round <- round(lat, 0)
  long_round <- round(long, 0)
  local_crs <- paste0(
    "+proj=laea +lat_0=", lat_round, " +lon_0=", long_round,
    " +x_0=4321000 +y_0=3210000 +ellps=GRS80 ",
    "+towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  )

  point_proj <- sf::st_transform(point_sf, crs = sf::st_crs(local_crs))
  bounding_shape <- sf::st_buffer(
    point_proj,
    dist = square_km * 1000,
    nQuadSegs = 1,
    endCapStyle = "SQUARE"
  )
  return(bounding_shape)
}

track_bounding_box <- function(lat_points, long_points, width_buffer) {

  points_sf <- sf::st_as_sf(
    data.frame(x = long_points, y = lat_points),
    coords = c("x", "y"),
    crs = 4326
  )
  bbox_poly <- sf::st_as_sfc(sf::st_bbox(points_sf))
  local_crs <- paste0(
    "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 ",
    "+ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  )
  bbox_proj <- sf::st_transform(bbox_poly, crs = sf::st_crs(local_crs))
  bounding_shape <- sf::st_buffer(bbox_proj, dist = width_buffer * 1000, endCapStyle = "SQUARE")
  return(bounding_shape)
}

# REPLACES slippymath::compose_tile_grid + raster::brick + raster slot access
# Builds a single SpatRaster from downloaded tile files.
# compose_tile_grid <- function(tile_grid, images) {
#
#   bricks <- purrr::pmap(
#     .l = list(x = tile_grid$tiles$x,
#               y = tile_grid$tiles$y,
#               image = images),
#     .f = function(x, y, image, zoom) {
#
#       bbox <- slippymath::tile_bbox(x, y, zoom)
#       crs_proj4 <- attr(bbox, "crs")$proj4string  # slippymath attaches CRS as attribute
#
#       # Load tile image as terra SpatRaster
#       raster_img <- terra::rast(image)
#
#       # Handle single-band paletted PNGs (slippymath downloads them as .jpg but they can be PNG)
#       # BEFORE: raster_img@legend@colortable + raster::setValues
#       # AFTER:  terra::coltab() returns data.frame(value, red, green, blue, alpha)
#       if (terra::nlyr(raster_img) == 1) {
#         ct <- terra::coltab(raster_img)[[1]]
#         if (!is.null(ct) && nrow(ct) > 0) {
#           vals <- as.integer(terra::values(raster_img)[, 1])
#           idx <- match(vals, ct$value)
#           r <- terra::setValues(raster_img, ct$red[idx])
#           g <- terra::setValues(raster_img, ct$green[idx])
#           b <- terra::setValues(raster_img, ct$blue[idx])
#           raster_img <- c(r, g, b)
#         }
#       }
#
#       # Assign geographic extent - terra::ext() replaces raster::extent()
#       terra::ext(raster_img) <- terra::ext(
#         c(bbox["xmin"], bbox["xmax"], bbox["ymin"], bbox["ymax"])
#       )
#       terra::crs(raster_img) <- crs_proj4
#
#       raster_img
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # Merge tiles - Reduce(terra::merge) replaces do.call(raster::merge, bricks)
#   if (length(bricks) == 1) {
#     bricks[[1]]
#   } else {
#     Reduce(function(a, b) terra::merge(a, b), bricks)
#   }
# }

# compose_tile_grid : restored to raster-based approach that worked
# Terra's merge of JPEG tiles with manually-assigned extents is unreliable.
# raster::brick + raster::merge handles this correctly — convert to terra after.

# compose_tile_grid <- function(tile_grid, images) {
#
#   bricks <- purrr::pmap(
#     .l = list(x = tile_grid$tiles$x,
#               y = tile_grid$tiles$y,
#               image = images),
#     .f = function(x, y, image, zoom) {
#
#       bbox <- slippymath::tile_bbox(x, y, zoom)
#
#       # raster::brick on a JPEG — suppress the proj4string deprecation warning
#       # (it still works correctly despite the warning)
#       raster_img <- suppressWarnings(
#         raster::brick(image, crs = attr(bbox, "crs")$proj4string)
#       )
#
#       # Handle single-band paletted PNGs
#       if (dim(raster_img)[3] == 1) {
#         raster_img <- suppressWarnings(
#           raster::raster(image, crs = attr(bbox, "crs")$proj4string)
#         )
#         raster_img <- raster::setValues(
#           raster::brick(raster_img, raster_img, raster_img),
#           t(grDevices::col2rgb(
#             raster_img@legend@colortable
#           ))[raster::values(raster_img) + 1, ]
#         )
#       }
#
#       # Assign geographic extent from slippymath bbox
#       raster::extent(raster_img) <- raster::extent(
#         bbox[c("xmin", "xmax", "ymin", "ymax")]
#       )
#       raster_img
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # Merge all tiles into one raster, then convert to terra SpatRaster
#   merged <- do.call(raster::merge, bricks)
#   terra::rast(merged)   # hand off to terra for everything downstream
# }

# compose_tile_grid <- function(tile_grid, images) {
#
#   bricks <- purrr::pmap(
#     .l = list(x = tile_grid$tiles$x,
#               y = tile_grid$tiles$y,
#               image = images),
#     .f = function(x, y, image, zoom) {
#
#       bbox <- slippymath::tile_bbox(x, y, zoom)
#
#       # Suppress the "unknown extent" warning because we set it manually 2 lines later
#       tile_rast <- suppressWarnings(terra::rast(image))
#
#       # Handle paletted PNGs: convert to RGB
#       if (terra::nlyr(tile_rast) == 1 && !is.null(terra::coltab(tile_rast))) {
#         tile_rast <- terra::colorize(tile_rast, to = "rgb")
#       }
#
#       # Assign the correct extent and CRS
#       terra::ext(tile_rast) <- c(bbox["xmin"], bbox["xmax"], bbox["ymin"], bbox["ymax"])
#       terra::crs(tile_rast) <- "EPSG:3857"
#
#       tile_rast
#     },
#     zoom = tile_grid$zoom
#   )
#
#   tile_collection <- terra::sprc(bricks)
#   terra::merge(tile_collection)
# }

# compose_tile_grid <- function(tile_grid, images) {
#
#   bricks <- purrr::pmap(
#     .l = list(x = tile_grid$tiles$x,
#               y = tile_grid$tiles$y,
#               image = images),
#     .f = function(x, y, image, zoom) {
#
#       bbox <- slippymath::tile_bbox(x, y, zoom)
#
#       tile_rast <- suppressWarnings(terra::rast(image))
#
#       # Use as.numeric to strip any slippymath attributes for a "clean" extent
#       terra::ext(tile_rast) <- as.numeric(c(bbox["xmin"], bbox["xmax"], bbox["ymin"], bbox["ymax"]))
#       terra::crs(tile_rast) <- "EPSG:3857"
#
#       if (terra::nlyr(tile_rast) == 1 && !is.null(terra::coltab(tile_rast))) {
#         tile_rast <- terra::colorize(tile_rast, to = "rgb")
#       }
#
#       tile_rast
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # Mosaic is superior for tiling as it handles pixel seams more precisely
#   tile_collection <- terra::sprc(bricks)
#   terra::merge(tile_collection)
# }

# compose_tile_grid <- function(tile_grid, images) {
#
#   # Use pmap to iterate over x, y, and image simultaneously
#   bricks <- purrr::pmap(
#     .l = list(x = tile_grid$tiles$x,
#               y = tile_grid$tiles$y,
#               image = images),
#     .f = function(x, y, image, zoom) {
#
#       # Get the bounding box for this specific tile
#       bbox <- slippymath::tile_bbox(x, y, zoom)
#
#       # Create the raster from the image
#       tile_rast <- suppressWarnings(terra::rast(image))
#
#       # Set extent using the coordinates from bbox
#       # Note: explicitly naming the vector elements for terra
#       terra::ext(tile_rast) <- c(bbox[["xmin"]], bbox[["xmax"]], bbox[["ymin"]], bbox[["ymax"]])
#       terra::crs(tile_rast) <- "EPSG:3857"
#
#       # Handle palette-based images (like watercolor)
#       if (terra::nlyr(tile_rast) == 1 && !is.null(terra::coltab(tile_rast))) {
#         tile_rast <- terra::colorize(tile_rast, to = "rgb")
#       }
#
#       return(tile_rast)
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # Merge the tiles together
#   tile_collection <- terra::sprc(bricks)
#   merged <- terra::merge(tile_collection)
#
#   return(merged)
# }

compose_tile_grid <- function(tile_grid, images) {
  bricks <- purrr::pmap(
    .l = list(x = tile_grid$tiles$x,
              y = tile_grid$tiles$y,
              image = images),
    .f = function(x, y, image, zoom) {
      bbox <- slippymath::tile_bbox(x, y, zoom)

      # Read image directly into terra
      tile_rast <- terra::rast(image)

      # Force the extent and CRS
      terra::ext(tile_rast) <- c(bbox[["xmin"]], bbox[["xmax"]], bbox[["ymin"]], bbox[["ymax"]])
      terra::crs(tile_rast) <- "EPSG:3857"

      # Standardize to RGB if it's a palette image
      if (terra::nlyr(tile_rast) == 1 && !is.null(terra::coltab(tile_rast))) {
        tile_rast <- terra::colorize(tile_rast, to = "rgb")
      }

      return(tile_rast)
    },
    zoom = tile_grid$zoom
  )

  # Use merge, but wrap in a SpatRasterCollection
  # This is the most stable way to join adjacent tiles in terra
  tile_collection <- terra::sprc(bricks)
  return(terra::merge(tile_collection))
}

# REPLACES raster slot access: tile_raster@data@values
# Normalises a multi-band SpatRaster and writes it as a PNG array
# raster_to_png <- function(tile_raster, file_path) {
#
#   nr <- terra::nrow(tile_raster)
#   nc <- terra::ncol(tile_raster)
#   nb <- terra::nlyr(tile_raster)
#
#   # terra::values() returns matrix [ncells × nbands]; rows are in raster row-major order
#   vals <- terra::values(tile_raster)
#   band_max <- apply(vals, 2, max, na.rm = TRUE)
#   vals_norm <- sweep(vals, 2, band_max, "/")       # normalise each band 0-1
#   vals_norm[is.na(vals_norm) | vals_norm < 0] <- 0
#   vals_norm[vals_norm > 1] <- 1
#
#   # Reshape to array [nrow, ncol, nbands] as png::writePNG expects
#   arr <- array(0, dim = c(nr, nc, nb))
#   for (i in seq_len(nb)) {
#     arr[,,i] <- matrix(vals_norm[, i], nrow = nr, ncol = nc, byrow = TRUE)
#   }
#
#   png::writePNG(arr, target = file_path)
# }

raster_to_png <- function(tile_raster, file_path) {
  # Ensure we have values and they are in the 0-255 range
  # If the raster is already 0-255, this just ensures it's compatible
  # with the PNG writer.
  terra::writeRaster(tile_raster,
                     filename = file_path,
                     overwrite = TRUE,
                     datatype = "INT1U")
}
