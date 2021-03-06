class CreateUserCourses < ActiveRecord::Migration
  def change
    create_table :user_courses do |t|
      t.boolean :active, default: false
      t.integer :user_id
      t.integer :course_id

      t.timestamps null: false
    end
    add_index :user_courses, [:user_id, :course_id], unique: true
  end
end
