# frozen_string_literal: true

module FlexPolyline
  # The format version.
  FORMAT_VERSION = 1

  # The constant for absent third dimension.
  ABSENT = 0
  # The constant for "LEVEL" third dimension.
  LEVEL = 1
  # The constant for "ALTITUDE" third dimension.
  ALTITUDE = 2
  # The constant for "ELEVATION" third dimension.
  ELEVATION = 3
  # Reserved values 4 and 5 should not be selectable

  # The constant for "CUSTOM1" third dimension.
  CUSTOM1 = 6
  # The constant for "CUSTOM2" third dimension.
  CUSTOM2 = 7

  # A hash mapping the third dimension type to the symbol representation.
  THIRD_DIM_MAP = {
    ALTITUDE => :alt, ELEVATION => :elv,
    LEVEL => :lvl, CUSTOM1 => :cst1, CUSTOM2 => :cst2
  }.freeze
end
