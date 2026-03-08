class MiniatureLock < ApplicationRecord
  belongs_to :miniature
  belongs_to :event
  belongs_to :army_list
end
