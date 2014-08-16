class BefParam
  def initialize(bef_param_str)
    @params = BefParam.parse(bef_param_str)
  end

  def to_s
    arr = @params.collect do |k,v|
      next if v.blank?
      if v.is_a? Array
        v.collect {|x| "#{k}:#{x}"}
      else
        "#{k}:#{v}"
      end
    end

    arr.flatten.compact.join(',')
  end

  def has_param?(arg, *options)
    options = options.extract_options!

    case arg
      when String, Symbol
        return @params[arg].present?
      when Hash
        arg.each do |k,v|
          if options[:exact]
            return false unless v.class == @params[k].class
            return false unless [v].flatten.sort == [@params[k]].flatten.sort
          else
            return false unless ([v].flatten - [@params[k]].flatten).length == 0
          end
        end
      else
        return false
    end

    return true
  end

  def get_param(name)
    @params[name]
  end

  alias [] get_param

  def dup
    self.class.new(self.to_s)
  end

  def set_param(args)
    self.dup.set_param!(args)
  end

  def set_param!(args)
    @params.merge! args
    return self
  end

  def []=(k,v)
    @params[k] = v
  end

  def self.parse(bef_param_str)
    parsed_params = HashWithIndifferentAccess.new
    return parsed_params if bef_param_str.blank?

    bef_param_str.split(',').each do |pairs|
      next unless pairs.include? ':'
      k,v = pairs.split(':')
      if parsed_params[k]
        if parsed_params[k].is_a? Array
          parsed_params[k].push v
        else
          parsed_params[k] = [parsed_params[k], v]
        end
      else
        parsed_params[k] = v
      end
    end

    parsed_params
  end
end
