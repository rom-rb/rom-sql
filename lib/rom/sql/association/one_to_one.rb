module ROM
  module SQL
    class Association
      class OneToOne < OneToMany
        result :one

        # @api private
        def remove_associated(relations, parent)
          pk, fk = join_key_map(relations)
          relation = relations[source.relation]
          relation.where(fk => parent.fetch(pk)).delete
        end
      end
    end
  end
end
