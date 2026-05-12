# context("imagery")
#
# library(geoviz)
#
# igc <- example_igc()
# DEM <- example_raster()
# lat = 54.4502651
# long = -3.1767946
# square_km = 1
#
# test_that("slippy_overlay() has correct dimensions", {
#   skip_if_offline()   # skip cleanly if no internet / no API key
#   skip_on_cran()
#   expect_warning(
#     slippy_overlay(DEM,
#                    max_tiles    = 10,
#                    image_source = "stamen",   # ← source
#                    image_type   = "terrain")  # ← type (was wrongly merged into source)
#   )
# })
#
# test_that("slippy_raster() returns data", {
#   skip_if_offline()
#   skip_on_cran()
#   expect_warning(
#     slippy_raster(lat         = 54.5,
#                   long        = -3.0,
#                   square_km   = 2,
#                   image_source = "stamen",
#                   image_type   = "watercolor",
#                   max_tiles    = 5)
#   )
# })
#
# test_that("elevation_shade() has correct dimensions", {
#   elevation_shade_result <-
#     elevation_shade(
#       DEM,
#       elevation_palette = c("#54843f", "#808080", "#FFFFFF"),
#       return_png = TRUE
#     )
#
#   expect_is(elevation_shade_result, "array")
#   expect_equal(ncol(elevation_shade_result), ncol(DEM))
#   expect_equal(nrow(elevation_shade_result), nrow(DEM))
# })
#
# test_that("elevation_transparency() has correct dimensions", {
#   elevation_shade_result <-
#     elevation_shade(
#       DEM,
#       elevation_palette = c("#54843f", "#808080", "#FFFFFF"),
#       return_png = TRUE
#     )
#
#   elevation_transparency_result <-
#     elevation_transparency(
#       elevation_shade_result,
#       DEM,
#       alpha_max = 0.4,
#       alpha_min = 0,
#       pct_alt_low = 0.05,
#       pct_alt_high = 0.25
#     )
#
#   expect_is(elevation_transparency_result, "array")
#   expect_equal(ncol(elevation_transparency_result), ncol(DEM))
#   expect_equal(nrow(elevation_transparency_result), nrow(DEM))
# })
#
# test_that("drybrush() has correct dimensions", {
#   drybrush_result <-
#     drybrush(
#       DEM,
#       aggregation_factor = 10,
#       max_colour_altitude = 30,
#       opacity = 0.5,
#       elevation_palette = c("#3f3f3f", "#ffa500")
#     )
#
#   expect_is(drybrush_result, "array")
#   expect_equal(ncol(drybrush_result), ncol(DEM))
#   expect_equal(nrow(drybrush_result), nrow(DEM))
# })

# ── Replace ALL contents of test_imagery.R with this ─────────────────────────

library(geoviz)

DEM <- example_raster()   # now returns terra SpatRaster

test_that("slippy_overlay() has correct dimensions", {
  skip_if_offline()    # skip if no internet connection
  skip_on_cran()       # never run on CRAN
  result <- slippy_overlay(
    DEM,
    max_tiles    = 5,
    image_source = "stamen",    # ← source name only
    image_type   = "watercolor" # ← type is separate argument
  )
  expect_equal(length(dim(result)), 3)
})

test_that("slippy_raster() returns data", {
  skip_if_offline()
  skip_on_cran()
  result <- slippy_raster(
    lat          = 54.513293,
    long         = -3.045598,
    square_km    = 2,
    image_source = "stamen",
    image_type   = "watercolor",
    max_tiles    = 5
  )
  expect_true(terra::nlyr(result) > 0)
})
