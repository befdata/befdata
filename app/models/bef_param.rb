class BefParam
  def initialize(bef_param_str, *config)
    @params = BefParam.parse(bef_param_str)
    @param_config = BefParam.parse_config(config.extract_options!)
  end

  def to_s
    arr = @params.collect do |k,v|
      next if v.blank?
      v_str = v.is_a?(Array) ? v.join('|') : v
      "#{k}:#{v_str}"
    end
    arr.compact.uniq.join(',')
  end

  # p.has_param?('access_code') checks existence
  # p.has_param?('access_code', '0') checks existence and value
  def has_param?(*args)
    return false if args.blank?
    k, v = args
    if v
      return false unless @params[k].present?
      if @param_config[k].eql? 'radio'
        return false unless v.class == @params[k].class
        return false unless [v].flatten.sort == [@params[k]].flatten.sort
      else
        return false unless ([v].flatten - [@params[k]].flatten).length == 0
      end
      return true
    else
      return @params[k].present?
    end
  end

  def get_param(name)
    @params[name]
  end

  alias [] get_param

  def []=(k,v)
    @params[k] = v
  end

  def dup
    self.class.new(self.to_s, @param_config)
  end

  def set_param(args)
    self.dup.set_param!(args)
  end

  def set_param!(args)
    @params.merge! args
    return self
  end

  def toggle_param(k, v1, *options)
    self.dup.toggle_param!(k, v1, *options)
  end

  def toggle_param!(k, v)
    p = get_param(k)
    if @param_config[k].eql? 'radio'
      has_param?(k, v) ? set_param!({k => nil}) : set_param!({k => v})
    else
      has_param?(k, v) ? set_param!({k => ([p].flatten - [v].flatten).reject(&:blank?).uniq}) : set_param!({k => [p, v].flatten.reject(&:blank?).uniq})
    end
  end

  def self.parse(bef_param_str)
    parsed_params = HashWithIndifferentAccess.new
    return parsed_params if bef_param_str.blank?

    bef_param_str.split(',').each do |pairs|
      next unless pairs.include? ':'
      k,v = pairs.split(':')
      parsed_params[k] = (v =~ /\|/ )? v.split('|') : v
    end
    parsed_params
  end

  def self.parse_config(config)
    parsed_config = HashWithIndifferentAccess.new('radio')
    config.each do |k,v|
      if %w{radio checkbox}.include?(k.to_s)
        [v].flatten.each do |x|
          parsed_config[x] = k.to_s
        end
      else
        parsed_config[k] = v.to_s
      end
    end
    parsed_config
  end
end
