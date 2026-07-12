class ReportingManager < ApplicationRecord
  belongs_to :user
  belongs_to :manager, :class_name=>"User"
  default_scope {where.not(status:'archived')}
end
