class NullDatagroup
  def nil?; true; end
  def present?; false; end
  def empty?; true; end
  def !; true; end

  def categories; []; end

  Datagroup.attribute_names.each do |f|
    define_method f do
      nil
    end
  end

  def self.decrement_counter(counter_name, id); ; end
  def self.increment_counter(counter_name, id); ; end

end
