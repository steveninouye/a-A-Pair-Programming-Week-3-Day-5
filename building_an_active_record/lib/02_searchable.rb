require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_str = self.hash_to_string(params, " AND ")
    parse_all(DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_str}
    SQL
  )
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
