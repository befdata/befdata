class Textvalue < ActiveRecord::Base
  def show_value
    "#{text}"
  end
end
