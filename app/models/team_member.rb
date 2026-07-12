class TeamMember < ApplicationRecord
  belongs_to :team
  belongs_to :user

  default_scope {where.not(status:'archived')}

  after_save :update_member_counts

  def update_member_counts
    user.update(:admin_teams_count=>user.admin_teams.count) if self.role == 'lead'
    team.update(:members_count=>team.members.count,:managers_count=>team.team_leads.active.count)
    team.project.update_attribute(:member_count, team.project.project_members.active.count)
  end
end
