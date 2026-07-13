# This file should contain all the record creation needed to seed the
# database with its default values. Load with `rake db:seed` (or `db:setup`).
#
# Two tiers:
#   Platform data - the admin login. Runs in every environment, including
#                   production, so there is always a way in.
#   Demo data     - a realistic org (Sitepeg — a fictional Australian civil
#                   construction SaaS) with department-level quarterly OKRs
#                   ("rocks", EOS-style) and staffed delivery squads, so the
#                   app isn't empty on first boot. Runs outside production,
#                   or in production only when SEED_DEMO=1 is set.
#
# Everything below uses find_or_create_by! and is safe to re-run. For a
# clean slate: `rake db:reset`.

module Seeds
  def self.demo?
    !Rails.env.production? || ENV['SEED_DEMO'] == '1'
  end
end

# --- Platform: admin login (all environments) ------------------------------
User.find_or_create_by!(email: 'admin@fluxday.io') do |user|
  user.name = 'Admin User'
  user.nickname = 'admin'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.employee_code = 'FT00'
  user.role = 'admin'
end

return unless Seeds.demo?

# --- Demo: Sitepeg, a fictional Australian civil-construction SaaS ---------
#
# Org shape:
#   - One company (`Project`): Sitepeg.
#   - Company-level quarterly OKRs ("rocks", EOS-style) owned by each
#     department lead: Product, Engineering, Sales, Customer Support.
#   - Three staffed delivery squads (`Team`s), each with 1 product owner +
#     8 engineers/designers, and its own squad-level OKR: Cost & Contract,
#     Field & Operations, Onboarding.

sitepeg_code_counter = 0
next_sitepeg_code = -> { sitepeg_code_counter += 1; format('SP-%03d', sitepeg_code_counter) }

seed_sitepeg_user = lambda do |name, role|
  local_part = name.downcase.delete("'").split.join('.')
  User.find_or_create_by!(email: "#{local_part}@sitepeg.io") do |user|
    user.name = name
    user.nickname = name.split.first
    user.password = 'password'
    user.password_confirmation = 'password'
    user.employee_code = next_sitepeg_code.call
    user.role = role
  end
end

quarter_start = Date.today.beginning_of_quarter
quarter_end = quarter_start.end_of_quarter

sitepeg = Project.find_or_create_by!(code: 'SPEG') do |p|
  p.name = 'Sitepeg'
  p.description = 'Cost, contract, and field management for Australian civil contractors.'
end

ceo = seed_sitepeg_user.call('Jordan Lee', 'Manager') # Founder & CEO
ProjectManager.find_or_create_by!(project: sitepeg, user: ceo)

# --- Company rocks: one quarterly OKR per department, owned by its lead ----
DEPARTMENT_ROCKS = [
  {
    department: 'Product',
    lead: 'Priya Nair', # VP Product
    objective: 'Ship the field-first cost & contract experience',
    key_results: [
      'Launch progress claim automation to 100% of GA sites',
      'Cut time-to-first-value for new sites from 10 days to 3',
    ],
  },
  {
    department: 'Engineering',
    lead: 'Daniel Ho', # VP Engineering
    objective: 'Make the platform rock-solid at scale',
    key_results: [
      'Reduce P1 incidents to zero',
      'Get API p95 latency under 300ms',
    ],
  },
  {
    department: 'Sales',
    lead: 'Grace Thompson', # Head of Sales
    objective: 'Win the mid-market civil contractor segment',
    key_results: [
      'Close $1.2M in new ARR',
      'Grow average deal size by 15%',
    ],
  },
  {
    department: 'Customer Support',
    lead: 'Marcus Webb', # Head of Customer Support
    objective: 'Make renewal a non-event',
    key_results: [
      'Hit 95% gross revenue retention',
      'Cut first-response time to under 2 business hours',
    ],
  },
].freeze

DEPARTMENT_ROCKS.each do |dept|
  lead = seed_sitepeg_user.call(dept[:lead], 'Manager')
  ReportingManager.find_or_create_by!(user: lead, manager: ceo)
  ProjectManager.find_or_create_by!(project: sitepeg, user: lead)

  rock = Okr.find_or_create_by!(name: "#{dept[:department]} quarterly rock", user: lead) do |okr|
    okr.start_date = quarter_start
    okr.end_date = quarter_end
    okr.approved = true
    okr.objectives_attributes = [{
      name: dept[:objective],
      user_id: lead.id,
      key_results_attributes: dept[:key_results].map { |kr| { name: kr, user_id: lead.id } },
    }]
  end

  kr = rock.key_results.first
  task = Task.find_or_create_by!(name: "#{dept[:department]} rock: #{kr.name}", project: sitepeg) do |t|
    t.description = "Company rock tracking task for #{dept[:department]}."
    t.user = lead
    t.start_date = quarter_start
    t.end_date = quarter_end
    t.priority = 'high'
  end
  TaskKeyResult.find_or_create_by!(task: task, key_result: kr)
end

product_lead = User.find_by!(email: 'priya.nair@sitepeg.io')

# --- Delivery squads: 1 product owner + 8 members, each with a squad OKR --
SQUADS = [
  {
    code: 'CC',
    name: 'Cost & Contract',
    po: 'Olivia Bennett', # Product Owner
    objective: 'Automate progress claims end to end',
    key_results: [
      'Ship claim-vs-budget variance view',
      'Cut claim prep time from 3 hours to 30 minutes',
    ],
    members: [
      "Noah Fitzgerald", "Ava Sinclair", "Liam O'Connell", "Chloe Dawson",
      "Mason Reid", "Harper Nguyen", "Lucas Whitfield", "Zoe Kaur"
    ],
  },
  {
    code: 'FO',
    name: 'Field & Operations',
    po: 'Ethan Walsh', # Product Owner
    objective: 'Give crews a phone-first daily site diary',
    key_results: [
      'Ship offline-first daily diary on the field app',
      'Get weekly active crew adoption to 80%',
    ],
    members: [
      'Isabella Cross', 'Jack Muller', 'Ruby Anderson', 'Oscar Da Silva',
      'Mia Talbot', 'Henry Okafor', 'Sophie Marsh', 'Leo Papadopoulos'
    ],
  },
  {
    code: 'OB',
    name: 'Onboarding',
    po: 'Isla Fraser', # Product Owner
    objective: 'Cut time-to-go-live for new sites',
    key_results: [
      'Ship the guided site setup wizard',
      'Reduce onboarding calls per customer from 4 to 1',
    ],
    members: [
      'Charlotte Ibrahim', 'Thomas Zhang', 'Amelia Novak', 'William Farrow',
      'Zara Ahmadi', 'Ryan Solomon', 'Ella Kowalski', 'Nathan Blake'
    ],
  },
].freeze

squads_seeded = SQUADS.map do |squad|
  team = Team.find_or_create_by!(code: squad[:code], project: sitepeg) do |t|
    t.name = squad[:name]
  end

  po = seed_sitepeg_user.call(squad[:po], 'Employee')
  ReportingManager.find_or_create_by!(user: po, manager: product_lead)
  TeamMember.find_or_create_by!(team: team, user: po) { |tm| tm.role = 'lead' }

  members = squad[:members].map do |name|
    member = seed_sitepeg_user.call(name, 'Employee')
    ReportingManager.find_or_create_by!(user: member, manager: po)
    TeamMember.find_or_create_by!(team: team, user: member)
    member
  end

  okr = Okr.find_or_create_by!(name: "#{squad[:name]} squad OKR", user: po) do |o|
    o.start_date = quarter_start
    o.end_date = quarter_end
    o.approved = true
    o.objectives_attributes = [{
      name: squad[:objective],
      user_id: po.id,
      key_results_attributes: squad[:key_results].map { |kr| { name: kr, user_id: po.id } },
    }]
  end

  tasks = okr.key_results.map.with_index do |kr, idx|
    assignee = members[idx] || po
    task = Task.find_or_create_by!(name: "#{squad[:name]}: #{kr.name}", project: sitepeg) do |t|
      t.description = "Delivery task for the #{squad[:name]} squad's key result: #{kr.name}"
      t.team = team
      t.user = assignee
      t.start_date = quarter_start
      t.end_date = quarter_start + 3.weeks
      t.priority = idx.zero? ? 'high' : 'medium'
    end
    TaskKeyResult.find_or_create_by!(task: task, key_result: kr)
    task
  end

  { team: team, po: po, members: members, tasks: tasks }
end

squads_seeded.first[:tasks].first.update!(status: 'completed') if squads_seeded.first[:tasks].first.status == 'active'

# --- A handful of work logs, so recent activity has something to show -----
WorkLog.find_or_create_by!(task: squads_seeded[0][:tasks].first, user: squads_seeded[0][:po], date: Date.today) do |log|
  log.name = 'Modelled variance calc against 3 pilot sites'
  log.minutes = 120
end
WorkLog.find_or_create_by!(task: squads_seeded[1][:tasks].first, user: squads_seeded[1][:members].first, date: Date.today) do |log|
  log.name = 'Field-tested offline sync in a 4G dead zone'
  log.minutes = 75
end
WorkLog.find_or_create_by!(task: squads_seeded[2][:tasks].first, user: squads_seeded[2][:po], date: Date.today) do |log|
  log.name = 'Mapped the current onboarding call script'
  log.minutes = 60
end
