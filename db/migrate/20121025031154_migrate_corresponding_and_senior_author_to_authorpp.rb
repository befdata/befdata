class MigrateCorrespondingAndSeniorAuthorToAuthorpp < ActiveRecord::Migration
  def self.up
    sql =  "INSERT INTO author_paperproposals(paperproposal_id, user_id,created_at, updated_at, kind) "
    sql += "SELECT id, corresponding_id,created_at, updated_at, 'user' as kind FROM paperproposals "
    sql += "UNION "
    sql += "SELECT id, senior_author_id,created_at, updated_at, 'user' as kind FROM paperproposals "
    sql += "ORDER BY id"
    execute(sql)

    remove_column :paperproposals, :corresponding_id
    remove_column :paperproposals, :senior_author_id
  end

  def self.down
    add_column :paperproposals, :corresponding_id,:integer
    add_column :paperproposals, :senior_author_id,:integer
  end
end
