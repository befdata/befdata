module ApplicationHelper
  include Acl9Helpers

  def tag_cloud(tag_counts, classes)
    return if tag_counts.blank?

    max = tag_counts.collect{|t| t.count.to_i }.max
    min = tag_counts.collect{|t| t.count.to_i }.min

    tag_counts.each { |t|
      index = (t.count.to_f - min) / (max - min) * (classes.size - 1)
      yield(t, classes[index.nan? ? 0 : index.round])
    }
  end

  def all_project_roles
    t("role").slice(:pi, :"co-pi", :postdoc, :"phd student",
                    :technician, :student).invert
  end

end
