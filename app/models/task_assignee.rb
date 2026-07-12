class TaskAssignee < ApplicationRecord
  belongs_to :task
  belongs_to :user

  default_scope {where.not(status:'archived')}
end
