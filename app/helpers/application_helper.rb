module ApplicationHelper
  include Acl9Helpers
  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each { |t|
      max = t.taggings.count.to_i if t.taggings.count.to_i > max
      min = t.taggings.count.to_i if t.taggings.count.to_i < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      yield t, classes[(t.taggings.count.to_i - min) / divisor]
    }
  end
  def all_project_roles
    t("role").slice(:pi, :"co-pi", :postdoc, :"phd student",
                    :technician, :student).invert
  end
end
