class Post < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true


  # broadcast_ : we can have these broadcasted for all user
  # Could be broadcast_append_to or broadcast_prepend_to
  after_create_commit {broadcast_append_to "posts"}
  after_update_commit {broadcast_replace_to "posts"}
  after_destroy_commit {broadcast_remove_to "posts"}
end
