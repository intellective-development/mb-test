# rubocop:disable Naming/PredicateName
module PiedPiper
  def self.included(base)
    base.extend(ClassMethods)
    class << base
      attr_accessor :__parent_key
    end

    base.__parent_key = 'parent_id'
  end

  def descendents
    self_and_descendents.where.not(id: id)
  end

  def parents(**options)
    self_and_parents(**options).where.not(id: id)
  end

  def self_and_descendents
    self.class.tree_for(id)
  end

  def self_and_parents(**options)
    self.class.parents_for(id, **options)
  end

  module ClassMethods
    def has_descendents(**options)
      self.__parent_key = options[:parent_key] if options.key?(:parent_key)
    end

    def tree_for(id)
      where("#{table_name}.id IN (#{tree_subquery(id)})").order(:id)
    end

    def parents_for(id, **options)
      where("#{table_name}.id IN (#{parent_subquery(id, **options)})").order(:id)
    end

    def tree_subquery(id)
      tree_sql = %{
        WITH RECURSIVE search_tree(id, path) AS (
            SELECT id, ARRAY[id]
            FROM #{table_name}
            WHERE id = :id
          UNION ALL
            SELECT #{table_name}.id, path || #{table_name}.id
            FROM search_tree
            JOIN #{table_name} ON #{table_name}.#{__parent_key} = search_tree.id
            WHERE NOT #{table_name}.id = ANY(path)
        )
        SELECT id FROM search_tree ORDER BY path
      }
      sanitize_sql_for_conditions([tree_sql.gsub(/\s+/, ' '), { id: id }])
    end

    def parent_subquery(id, depth: 3)
      parent_sql = %{
        WITH RECURSIVE search_parents(id, #{__parent_key}, depth) AS (
          SELECT id, #{__parent_key}, 1 AS depth
          FROM #{table_name}
          WHERE id = :id
        UNION ALL
          SELECT #{table_name}.id, #{table_name}.#{__parent_key}, depth + 1
          FROM search_parents, #{table_name}
          WHERE search_parents.#{__parent_key} = #{table_name}.id AND depth < :depth
        )
        SELECT id FROM search_parents ORDER BY id
      }
      sanitize_sql_for_conditions([parent_sql.gsub(/\s+/, ' '), { id: id, depth: depth }])
    end
  end
end
# rubocop:enable Naming/PredicateName
