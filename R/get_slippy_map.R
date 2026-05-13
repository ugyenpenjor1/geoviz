#' Obtains and merges map tiles from various sources using the 'slippymath' package
#'
#' @param bounding_box Any object for which raster::extent() can be calculated.
#' @param image_source Source for the overlay image. Valid entries are "mapbox", "mapzen", "stamen".
#' @param image_type The type of overlay to request. "satellite", "mapbox-streets-v8", "mapbox-terrain-v2", "mapbox-traffic-v1", "terrain-rgb", "mapbox-incidents-v1" (mapbox), "dem" (mapzen) or "watercolor", "toner", "toner-background", "toner-lite" (stamen). You can also request a custom Mapbox style by specifying \code{image_source = "mapbox", image_type = "username/mapid"}
#' @param max_tiles Maximum number of tiles to be requested by 'slippymath'
#' @param api_key API key (required for 'mapbox')
#'
#' @return a rasterBrick with the same dimensions (but not the same resolution) as bounding_box
#'
#' @examples
#' map <- get_slippy_map(example_raster(),
#'   image_source = "stamen",
#'   image_type = "watercolor",
#'   max_tiles = 5)
#' @export
# get_slippy_map <- function(bounding_box, image_source = "stamen", image_type = "watercolor", max_tiles = 10, api_key) {
#
#   # ── Transform bounding_box to WGS84 ─────────────────────────────────────────
#   # BEFORE: mixed sp/raster approach that breaks on sf objects
#   # AFTER:  handle both Raster and sf/sfc objects cleanly
#
#   if (inherits(bounding_box, "Raster")) {
#     # Raster object — reproject using raster
#     bounding_box <- raster::projectRaster(
#       bounding_box,
#       crs = "+proj=longlat +datum=WGS84 +no_defs"
#     )
#     xt <- raster::extent(bounding_box)
#     overlay_bbox <- sf::st_bbox(
#       c(xmin = xt@xmin, xmax = xt@xmax, ymin = xt@ymin, ymax = xt@ymax),
#       crs = sf::st_crs(4326)
#     )
#
#   } else {
#     # sf / sfc object — use sf::st_transform instead of sp::spTransform
#     bounding_box <- sf::st_transform(bounding_box, crs = 4326)
#     overlay_bbox <- sf::st_bbox(bounding_box)
#   }
#
#   # ── Build tile grid ───────────────────────────────────────────────────────────
#   tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, max_tiles = max_tiles)
#
#   if (tile_grid$zoom > 11 & image_source == "mapbox" & image_type == "terrain-rgb") {
#     message(glue::glue("Zoom level with max_tiles = {max_tiles} is {tile_grid$zoom}. Resetting zoom to 11, which is max for mapbox.terrain-rgb."))
#     tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, zoom = 11)
#   }
#
#   # ── Build query string ────────────────────────────────────────────────────────
#   # NOTE: slippymath uses {z} not {zoom} in URL templates
#   # Stamen tiles moved from tile.stamen.com to Stadia in 2023
#
#   if (image_source == "stamen") {
#
#     # Map old stamen image_type names to new Stadia URL paths
#     stamen_type <- switch(image_type,
#                           "watercolor"        = "stamen_watercolor",
#                           "toner"             = "stamen_toner",
#                           "toner-background"  = "stamen_toner_background",
#                           "toner-lite"        = "stamen_toner_lite",
#                           "terrain"           = "stamen_terrain",
#                           paste0("stamen_", image_type)   # fallback for any other type
#     )
#
#     ext <- ifelse(stringr::str_detect(image_type, "watercolor"), "jpg", "png")
#     query_string <- paste0(
#       "https://tiles.stadiamaps.com/tiles/", stamen_type,
#       "/{z}/{x}/{y}.", ext
#     )
#
#   } else if (image_source == "mapbox") {
#
#     if (stringr::str_detect(image_type, "\\/")) {
#       # Custom Mapbox style URL
#       query_string <- paste0(
#         "https://api.mapbox.com/styles/v1/", image_type,
#         "/tiles/{z}/{x}/{y}?access_token=", api_key
#       )
#     } else {
#       # Standard Mapbox tileset
#       query_string <- paste0(
#         "https://api.mapbox.com/v4/mapbox.", image_type,
#         "/{z}/{x}/{y}.jpg90?access_token=", api_key
#       )
#     }
#
#   } else if (image_source == "mapzen" & image_type == "dem") {
#     query_string <- "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
#
#   } else if (image_source == "osm") {
#     query_string <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
#
#   } else {
#     stop(glue::glue("Unknown source '{image_source}'"))
#   }
#
#   # ── Download tiles ────────────────────────────────────────────────────────────
#   tile_dir <- tempfile(pattern = "map_tiles_")
#   dir.create(tile_dir)
#
#   # images <- purrr::pmap(
#   #   tile_grid$tiles,
#   #   function(x, y, zoom) {
#   #     outfile <- glue::glue("{tile_dir}/{x}_{y}.jpg")
#   #     curl::curl_download(
#   #       url      = glue::glue(query_string),
#   #       destfile = outfile
#   #     )
#   #     outfile
#   #   },
#   #   zoom = tile_grid$zoom
#   # )
#   images <- purrr::pmap(
#     tile_grid$tiles,
#     function(x, y, zoom) {
#
#       z <- zoom
#
#       outfile <- glue::glue("{tile_dir}/{x}_{y}.jpg")
#
#       curl::curl_download(
#         url      = glue::glue(query_string, z = zoom), #glue::glue(query_string),
#         destfile = outfile
#       )
#
#       outfile
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # ── Compose and reproject output raster ──────────────────────────────────────
#   raster_out <- compose_tile_grid(tile_grid, images)
#   raster_out <- raster::projectRaster(raster_out, crs = raster::crs(bounding_box))
#
#   unlink(tile_dir, recursive = TRUE)
#   return(raster_out)
# }

# get_slippy_map <- function(bounding_box, image_source = "stamen",
#                            image_type = "watercolor", max_tiles = 10, api_key) {
#
#   if (inherits(bounding_box, "SpatRaster")) {
#     orig_crs <- terra::crs(bounding_box)
#
#     # Step 1: extract extent as a SpatVector polygon in the raster's own CRS
#     ext_poly <- terra::as.polygons(
#       terra::ext(bounding_box),
#       crs = terra::crs(bounding_box)
#     )
#
#     # Step 2: project that tiny polygon to WGS84 — fast, no raster data moved
#     ext_poly_wgs84 <- terra::project(ext_poly, "EPSG:4326")
#
#     # Step 3: build sf bbox — guaranteed valid coordinates
#     overlay_bbox <- sf::st_bbox(sf::st_as_sf(ext_poly_wgs84))
#
#   } else {
#     # orig_crs     <- sf::st_crs(bounding_box)$wkt
#     # bounding_box <- sf::st_transform(bounding_box, crs = 4326)
#     # overlay_bbox <- sf::st_bbox(bounding_box)
#     orig_crs     <- "EPSG:4326"                     # ← always WGS84, never LAEA
#     bounding_box <- sf::st_transform(bounding_box, crs = 4326)
#     overlay_bbox <- sf::st_bbox(bounding_box)
#   }
#
#   # ── Build tile grid ──────────────────────────────────────────────────────────
#   tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, max_tiles = max_tiles)
#
#   if (tile_grid$zoom > 11 && image_source == "mapbox" && image_type == "terrain-rgb") {
#     message(glue::glue("Zoom {tile_grid$zoom} > 11 (mapbox terrain-rgb max). Resetting to 11."))
#     tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, zoom = 11)
#   }
#
#   # ── Build tile URL template ──────────────────────────────────────────────────
#   if (image_source == "stamen") {
#
#     # Stamen tiles moved from tile.stamen.com to Stadia Maps in 2023.
#     # Map old image_type names to new Stadia tile path names.
#     stamen_type <- switch(image_type,
#                           "watercolor"        = "stamen_watercolor",
#                           "toner"             = "stamen_toner",
#                           "toner-background"  = "stamen_toner_background",
#                           "toner-lite"        = "stamen_toner_lite",
#                           "terrain"           = "stamen_terrain",
#                           paste0("stamen_", image_type)   # pass-through for any future types
#     )
#     ext <- if (stringr::str_detect(image_type, "watercolor")) "jpg" else "png"
#
#     if (!missing(api_key) && nchar(api_key) > 0) {
#       # Stadia key supplied — full quality Stamen tiles
#       query_string <- paste0(
#         "https://tiles.stadiamaps.com/tiles/", stamen_type,
#         "/{z}/{x}/{y}.", ext, "?api_key=", api_key
#       )
#     } else {
#       # No key — fall back to free OpenStreetMap tiles
#       message("No Stadia API key supplied. Falling back to OpenStreetMap.")
#       message("Get a free key at https://stadiamaps.com to restore Stamen tile quality.")
#       query_string <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
#     }
#
#   } else if (image_source == "osm") {
#     # OpenStreetMap — free, no key, good for general topographic context
#     query_string <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
#
#   } else if (image_source == "mapbox") {
#     # Mapbox — best option for high-resolution satellite imagery.
#     # Free token at https://account.mapbox.com
#     # Use image_type = "satellite" for aerial imagery.
#     if (stringr::str_detect(image_type, "\\/")) {
#       # Custom Mapbox style URL (format: "username/style_id")
#       query_string <- paste0(
#         "https://api.mapbox.com/styles/v1/", image_type,
#         "/tiles/{z}/{x}/{y}?access_token=", api_key
#       )
#     } else {
#       # Standard Mapbox tileset (satellite, terrain-rgb, etc.)
#       query_string <- paste0(
#         "https://api.mapbox.com/v4/mapbox.", image_type,
#         "/{z}/{x}/{y}.jpg90?access_token=", api_key
#       )
#     }
#
#   } else if (image_source == "mapzen" && image_type == "dem") {
#     query_string <- "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"
#
#   } else {
#     stop(glue::glue(
#       "Unknown image_source '{image_source}'. ",
#       "Valid options: 'stamen', 'osm', 'mapbox', 'mapzen'."
#     ))
#   }
#
#   # ── Download tiles ───────────────────────────────────────────────────────────
#   tile_dir <- tempfile(pattern = "map_tiles_")
#   dir.create(tile_dir)
#
#   images <- purrr::pmap(
#     tile_grid$tiles,
#     function(x, y, zoom) {
#       z       <- zoom   # glue needs variable named 'z' for {z} in URL template
#       outfile <- glue::glue("{tile_dir}/{x}_{y}.jpg")
#       curl::curl_download(url = glue::glue(query_string), destfile = outfile)
#       outfile
#     },
#     zoom = tile_grid$zoom
#   )
#
#   # ── Compose, reproject and return ───────────────────────────────────────────
#   # compose_tile_grid returns a SpatRaster
#   # terra::project replaces raster::projectRaster
#   raster_out <- compose_tile_grid(tile_grid, images)
#   raster_out <- terra::project(raster_out, orig_crs)
#
#   unlink(tile_dir, recursive = TRUE)
#   return(raster_out)
# }


get_slippy_map <- function(bounding_box, image_source = "stamen",
                           image_type = "watercolor", max_tiles = 10, api_key) {

  if (inherits(bounding_box, "SpatRaster")) {
    ext_poly       <- terra::as.polygons(terra::ext(bounding_box), crs = terra::crs(bounding_box))
    ext_poly_wgs84 <- terra::project(ext_poly, "EPSG:4326")
    overlay_bbox   <- sf::st_bbox(sf::st_as_sf(ext_poly_wgs84))

  } else {
    # Always WGS84 — never store LAEA/UTM as orig_crs
    bounding_box <- sf::st_transform(bounding_box, crs = 4326)
    overlay_bbox <- sf::st_bbox(bounding_box)
  }

  tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, max_tiles = max_tiles)

  if (tile_grid$zoom > 11 && image_source == "mapbox" && image_type == "terrain-rgb") {
    message(glue::glue("Zoom {tile_grid$zoom} > 11. Resetting to 11 for terrain-rgb."))
    tile_grid <- slippymath::bbox_to_tile_grid(overlay_bbox, zoom = 11)
  }

  if (image_source == "stamen") {
    stamen_type <- switch(image_type,
                          "watercolor"       = "stamen_watercolor",
                          "toner"            = "stamen_toner",
                          "toner-background" = "stamen_toner_background",
                          "toner-lite"       = "stamen_toner_lite",
                          "terrain"          = "stamen_terrain",
                          paste0("stamen_", image_type)
    )
    ext <- if (stringr::str_detect(image_type, "watercolor")) "jpg" else "png"
    if (!missing(api_key) && nchar(api_key) > 0) {
      query_string <- paste0("https://tiles.stadiamaps.com/tiles/", stamen_type,
                             "/{z}/{x}/{y}.", ext, "?api_key=", api_key)
    } else {
      message("No Stadia API key — falling back to OpenStreetMap.")
      query_string <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    }

  } else if (image_source == "osm") {
    query_string <- "https://tile.openstreetmap.org/{z}/{x}/{y}.png"

  } else if (image_source == "mapbox") {
    if (stringr::str_detect(image_type, "\\/")) {
      query_string <- paste0("https://api.mapbox.com/styles/v1/", image_type,
                             "/tiles/{z}/{x}/{y}?access_token=", api_key)
    } else {
      query_string <- paste0("https://api.mapbox.com/v4/mapbox.", image_type,
                             "/{z}/{x}/{y}.jpg90?access_token=", api_key)
    }

  } else if (image_source == "mapzen" && image_type == "dem") {
    query_string <- "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"

  } else {
    stop(glue::glue("Unknown image_source '{image_source}'. Use: stamen, osm, mapbox, mapzen."))
  }

  tile_dir <- tempfile(pattern = "map_tiles_")
  dir.create(tile_dir)

  images <- purrr::pmap(
    tile_grid$tiles,
    function(x, y, zoom) {
      z       <- zoom
      outfile <- glue::glue("{tile_dir}/{x}_{y}.jpg")
      curl::curl_download(url = glue::glue(query_string), destfile = outfile)
      outfile
    },
    zoom = tile_grid$zoom
  )

  # Return tiles in WGS84 — slippy_overlay handles reprojection to match raster_base
  raster_out <- compose_tile_grid(tile_grid, images)

  unlink(tile_dir, recursive = TRUE)
  return(raster_out)
}
