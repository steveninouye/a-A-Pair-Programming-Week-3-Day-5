require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2("SELECT * FROM #{table_name}")[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        instance_variable_get("@attributes")[column]
      end
      define_method("#{column}=".to_sym) do |value|
        @attributes ||= {}
        @attributes[column] = value
        instance_variable_set("@attributes", @attributes)
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
    @table_name
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.parse_all(results)
    results.map { |obj| self.new(obj) }
  end

  def self.find(id)
    result = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ?", id)
    result.empty? ? nil : parse_all(result).first
  end

  def initialize(params = {})
    self.class.finalize!
    vals = params.values
    params.keys.each_with_index do |column, i|
      raise "unknown attribute '#{column}'" unless methods.include?(column.to_sym)
      self.send("#{column}=", vals[i])
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    @attributes.values
  end

  def insert
    keys = @attributes.keys.join(", ")
    vals = "'" + @attributes.values.join("', '") + "'"
    DBConnection.execute(<<-SQL)
      INSERT INTO #{self.class.table_name}
        (#{keys})
      VALUES
        (#{vals});
    SQL
    self.id = self.class.all.last.id
  end

  def update
    keys = @attributes.keys
    vals = @attributes.values
    id_idx = keys.index(:id)
    if id_idx
      keys.delete_at(id_idx)
      vals.delete_at(id_idx)
    end
    new_vals = keys.map.with_index{|e,i| "#{e} = \'#{vals[i]}\'"}
    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
        #{new_vals.join(", ")}
      WHERE
        id = #{attributes[:id]}
    SQL
  end

  def save
    if @attributes && @attributes[:id]
      update
    else
      insert
    end
  end
end
