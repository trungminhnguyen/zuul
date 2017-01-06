# Class holding the environment configuration
class EnvConfig
  def initialize(vars)
    config = get_required_variables(vars)
    config.each do |var_name, var_value|
      self.class.send(:define_method, var_name) do
        var_value
      end
    end
  end

  def get_required_variables(vars)
    missing_vars = vars.select do |var|
      ENV[var].nil?
    end
    raise("Undefined variables: #{missing_vars.join(' ')}") \
      unless missing_vars.empty?

    vars.each_with_object({}) do |var, vars_hash|
      vars_hash[var.sub(/^.*?_/, '').downcase] = ENV[var]
    end
  end

  private :get_required_variables
end
