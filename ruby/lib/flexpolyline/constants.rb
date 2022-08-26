# frozen_string_literal: true

module FlexPolyline
  FORMAT_VERSION = 1
  ABSENT = 0
  LEVEL = 1
  ALTITUDE = 2
  ELEVATION = 3
  # Reserved values 4 and 5 should not be selectable
  CUSTOM1 = 6
  CUSTOM2 = 7

  THIRD_DIM_MAP = {
    ALTITUDE => :alt, ELEVATION => :elv,
    LEVEL => :lvl, CUSTOM1 => :cst1, CUSTOM2 => :cst2
  }.freeze
end
