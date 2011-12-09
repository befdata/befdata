class LayoutHelper
  layout = SITE_CONFIG[:layout] || "application"

  BEF_LAYOUT = layout
  LAYOUT_IS_DEFAULT = (layout == "application")
end