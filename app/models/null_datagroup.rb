class NullDatagroup
  def nil?; true; end
  def present?; false; end
  def empty?; true; end
  def !; true; end

  def self.decrement_counter(counter_name, id); ; end
  def self.increment_counter(counter_name, id); ; end

  def method_missing(method_name, *args)
    Datagroup.new.send method_name, *args
  end
end
