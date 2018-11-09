class AttrAccessorObject
  def self.my_attr_accessor(*names) # [:x, :y]
    # ...
    names.each do |method_name|
      define_method(method_name) do
        instance_variable_get("@#{method_name}")
      end
      define_method("#{method_name}=") do |value|
        instance_variable_set("@#{method_name}", value)
      end
    end
  end
end
