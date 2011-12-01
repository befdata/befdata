class LayoutHelper
  layout = ActiveRecord::Base.configurations[::Rails.env]["layout"]
  if layout.nil? then
    layout = "application"
  end

  BEF_LAYOUT = layout
  LAYOUT_IS_DEFAULT = (layout == "application")
end