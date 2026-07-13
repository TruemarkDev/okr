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

# employee_code is derived from the name rather than a run counter, so it
# stays the same regardless of which users already exist on a given run
# (a run counter would drift out of sync across partial/crashed runs).
seed_sitepeg_user = lambda do |name, role|
  local_part = name.downcase.delete("'").split.join('.')
  User.find_or_create_by!(email: "#{local_part}@sitepeg.io") do |user|
    user.name = name
    user.nickname = name.split.first
    user.password = 'password'
    user.password_confirmation = 'password'
    user.employee_code = "SP-#{local_part.tr('.', '-').upcase}"
    user.role = role
  end
end

quarter_label = ->(date) { "Q#{((date.month - 1) / 3) + 1} #{date.year}" }

# Five continuous quarters: last year's same quarter through this one (4
# closed-out historical quarters + the current, in-flight quarter). Each
# entity's `history:` array supplies one entry per historical quarter, in
# order, each flagged `achieved: true/false` so outcomes vary quarter to
# quarter instead of everything landing as a uniform success streak.
first_quarter_start = (Date.today - 1.year).beginning_of_quarter
quarters = (0..4).map do |i|
  start_date = first_quarter_start + (i * 3).months
  {
    index: i,
    current: i == 4,
    start_date: start_date,
    end_date: start_date.end_of_quarter,
    label: quarter_label.call(start_date),
  }
end

sitepeg = Project.find_or_create_by!(code: 'SPEG') do |p|
  p.name = 'Sitepeg'
  p.description = 'Cost, contract, and field management for Australian civil contractors.'
end

ceo = seed_sitepeg_user.call('Jordan Lee', 'Manager') # Founder & CEO
ProjectManager.find_or_create_by!(project: sitepeg, user: ceo)

leadership_team = Team.find_or_create_by!(code: 'LEAD', project: sitepeg) do |t|
  t.name = 'Leadership'
end
TeamMember.find_or_create_by!(team: leadership_team, user: ceo) { |tm| tm.role = 'lead' }

# --- Company rocks: one quarterly OKR per department, owned by its lead ----
# Each department carries a `history:` (4 closed-out past quarters, oldest
# first, each flagged achieved: true/false) and a `current:` rock (this
# quarter's, still in flight). Q1 2026 is a company-wide miss across every
# department/squad — the platform migration ate everyone's roadmap capacity
# that quarter — so success isn't a uniform streak.
DEPARTMENT_ROCKS = [
  {
    department: 'Product',
    lead: 'Priya Nair', # VP Product
    history: [
      { achieved: true, objective: 'Launched the mobile field app', key_results: [
        'Shipped daily site diary to all pilot sites', 'Reached 60% weekly crew adoption',
      ] },
      { achieved: true, objective: 'Rolled out cost tracking to the mobile app', key_results: [
        'Shipped budget-vs-actual view to mobile', 'Reached 75% weekly crew adoption',
      ] },
      { achieved: false, objective: 'Launch the subcontractor compliance hub', key_results: [
        'Ship subcontractor insurance & licence tracking', 'Get 50% of subbies self-registering',
      ] },
      { achieved: true, objective: 'Simplified the progress claim workflow', key_results: [
        'Cut claim submission steps from 12 to 5', 'Launch claim templates for the top 5 trades',
      ] },
    ],
    current: {
      objective: 'Ship the field-first cost & contract experience',
      key_results: [
        'Launch progress claim automation to 100% of GA sites',
        'Cut time-to-first-value for new sites from 10 days to 3',
      ],
    },
  },
  {
    department: 'Engineering',
    lead: 'Daniel Ho', # VP Engineering
    history: [
      { achieved: true, objective: 'Migrated the core platform to the cloud', key_results: [
        'Migrated 100% of tenants off legacy servers', 'Cut deploy time from 45 minutes to 5',
      ] },
      { achieved: true, objective: 'Hardened platform security', key_results: [
        'Pass SOC 2 Type I audit', 'Close all critical/high vulnerabilities',
      ] },
      { achieved: false, objective: 'Ship multi-region failover', key_results: [
        'Stand up a hot standby in a second region', 'Cut RTO to under 15 minutes',
      ] },
      { achieved: true, objective: 'Cleaned up tech debt from the migration', key_results: [
        'Retire the last legacy server', 'Cut background job failure rate to under 1%',
      ] },
    ],
    current: {
      objective: 'Make the platform rock-solid at scale',
      key_results: [
        'Reduce P1 incidents to zero',
        'Get API p95 latency under 300ms',
      ],
    },
  },
  {
    department: 'Sales',
    lead: 'Grace Thompson', # Head of Sales
    history: [
      { achieved: true, objective: 'Established the mid-market motion', key_results: [
        'Closed $650K in new ARR', 'Signed the first 10 mid-market contractors',
      ] },
      { achieved: true, objective: 'Built the outbound sales motion', key_results: [
        'Hired and ramped 2 SDRs', 'Booked 40 qualified demos',
      ] },
      { achieved: false, objective: 'Launch the Sitepeg partner/reseller program', key_results: [
        'Sign 5 reseller partners', 'Generate $200K in partner-sourced pipeline',
      ] },
      { achieved: true, objective: 'Expanded into Queensland and WA', key_results: [
        'Closed 8 new logos outside Victoria', 'Opened a Brisbane sales presence',
      ] },
    ],
    current: {
      objective: 'Win the mid-market civil contractor segment',
      key_results: [
        'Close $1.2M in new ARR',
        'Grow average deal size by 15%',
      ],
    },
  },
  {
    department: 'Customer Support',
    lead: 'Marcus Webb', # Head of Customer Support
    history: [
      { achieved: true, objective: 'Stood up a dedicated onboarding function', key_results: [
        'Reduced onboarding time from 6 weeks to 3', 'Hit 90% CSAT on support tickets',
      ] },
      { achieved: true, objective: 'Stood up self-serve support', key_results: [
        'Launched the help centre', 'Deflected 30% of tickets to self-serve',
      ] },
      { achieved: false, objective: 'Launch proactive health scoring', key_results: [
        'Ship a customer health score to CS', 'Flag at-risk accounts 30 days before renewal',
      ] },
      { achieved: true, objective: 'Cut support backlog to zero', key_results: [
        'Cleared the aged-ticket backlog', 'Hit first-response time under 4 hours',
      ] },
    ],
    current: {
      objective: 'Make renewal a non-event',
      key_results: [
        'Hit 95% gross revenue retention',
        'Cut first-response time to under 2 business hours',
      ],
    },
  },
].freeze

DEPARTMENT_ROCKS.each do |dept|
  lead = seed_sitepeg_user.call(dept[:lead], 'Manager')
  ReportingManager.find_or_create_by!(user: lead, manager: ceo)
  ProjectManager.find_or_create_by!(project: sitepeg, user: lead)
  TeamMember.find_or_create_by!(team: leadership_team, user: lead)

  quarters.each do |quarter|
    content = quarter[:current] ? dept[:current] : dept[:history][quarter[:index]]

    rock = Okr.find_or_create_by!(name: "#{dept[:department]} quarterly rock — #{quarter[:label]}", user: lead) do |okr|
      okr.start_date = quarter[:start_date]
      okr.end_date = quarter[:end_date]
      okr.approved = true
      okr.objectives_attributes = [{
        name: content[:objective],
        user_id: lead.id,
        key_results_attributes: content[:key_results].map { |kr| { name: kr, user_id: lead.id } },
      }]
    end

    kr = rock.key_results.first
    task = Task.find_or_create_by!(name: "#{dept[:department]} rock (#{quarter[:label]}): #{kr.name}", project: sitepeg) do |t|
      t.description = "Company rock tracking task for #{dept[:department]}."
      t.team = leadership_team
      t.user = lead
      t.start_date = quarter[:start_date]
      t.end_date = quarter[:end_date]
      t.priority = 'high'
    end
    TaskKeyResult.find_or_create_by!(task: task, key_result: kr)

    # Work logs can't be backdated (WorkLog only allows the last 6 days), so
    # a closed-out quarter is represented by task status instead: completed
    # (and backdated) when the rock was achieved, left active/overdue when
    # it was missed.
    next if quarter[:current] || !content[:achieved]
    next unless task.status == 'active'

    task.update!(status: 'completed')
    task.update_column(:completed_on, quarter[:end_date] - 3.days)
  end
end

product_lead = User.find_by!(email: 'priya.nair@sitepeg.io')

# --- Delivery squads: 1 product owner + 8 members, each with a squad OKR --
# Each squad carries a `history:` (4 closed-out past quarters, oldest first,
# each flagged achieved: true/false) and a `current:` OKR (this quarter's,
# in flight). Q1 2026 misses across the board, same story as the company
# rocks above (the platform migration ate everyone's roadmap capacity).
SQUADS = [
  {
    code: 'CC',
    name: 'Cost & Contract',
    po: 'Olivia Bennett', # Product Owner
    history: [
      { achieved: true, objective: 'Digitised the paper-based progress claim', key_results: [
        'Replaced spreadsheet claims with in-app claims for 100% of sites', 'Cut claim errors by 50%',
      ] },
      { achieved: true, objective: 'Added budget tracking to claims', key_results: [
        'Ship budget-vs-actual on every claim', 'Cut variance-reporting time by 40%',
      ] },
      { achieved: false, objective: 'Ship multi-currency contracts', key_results: [
        'Support NZD alongside AUD', 'Migrate 20 pilot contracts to multi-currency',
      ] },
      { achieved: true, objective: 'Simplified claim approvals', key_results: [
        'Cut claim approval steps from 5 to 2', 'Get approval turnaround under 24 hours',
      ] },
    ],
    current: {
      objective: 'Automate progress claims end to end',
      key_results: [
        'Ship claim-vs-budget variance view',
        'Cut claim prep time from 3 hours to 30 minutes',
      ],
    },
    members: [
      "Noah Fitzgerald", "Ava Sinclair", "Liam O'Connell", "Chloe Dawson",
      "Mason Reid", "Harper Nguyen", "Lucas Whitfield", "Zoe Kaur"
    ],
  },
  {
    code: 'FO',
    name: 'Field & Operations',
    po: 'Ethan Walsh', # Product Owner
    history: [
      { achieved: true, objective: 'Shipped the first version of the field app', key_results: [
        'Launched the offline site diary MVP', 'Onboarded 15 crews to the field app',
      ] },
      { achieved: true, objective: 'Scaled the field app to 50 sites', key_results: [
        'Onboarded 50 sites to the field app', 'Cut crash rate to under 0.5%',
      ] },
      { achieved: false, objective: 'Ship equipment & plant tracking', key_results: [
        'Ship plant check-in/check-out on the field app', 'Track 80% of hired plant',
      ] },
      { achieved: true, objective: 'Added WHS checklists to the field app', key_results: [
        'Shipped the daily WHS checklist', 'Got 90% daily completion across sites',
      ] },
    ],
    current: {
      objective: 'Give crews a phone-first daily site diary',
      key_results: [
        'Ship offline-first daily diary on the field app',
        'Get weekly active crew adoption to 80%',
      ],
    },
    members: [
      'Isabella Cross', 'Jack Muller', 'Ruby Anderson', 'Oscar Da Silva',
      'Mia Talbot', 'Henry Okafor', 'Sophie Marsh', 'Leo Papadopoulos'
    ],
  },
  {
    code: 'OB',
    name: 'Onboarding',
    po: 'Isla Fraser', # Product Owner
    history: [
      { achieved: true, objective: 'Built the initial onboarding playbook', key_results: [
        'Documented the standard onboarding runbook', 'Cut new-site setup time from 3 weeks to 1',
      ] },
      { achieved: true, objective: 'Automated the onboarding checklist', key_results: [
        'Shipped the in-app onboarding checklist', 'Cut manual onboarding tasks by 50%',
      ] },
      { achieved: false, objective: 'Ship self-serve onboarding', key_results: [
        'Launch a self-serve setup flow', 'Get 30% of new sites self-onboarding',
      ] },
      { achieved: true, objective: 'Cut time-to-first-claim for new sites', key_results: [
        'Got first claim submitted within 5 days of go-live', 'Reduced onboarding calls from 4 to 2',
      ] },
    ],
    current: {
      objective: 'Cut time-to-go-live for new sites',
      key_results: [
        'Ship the guided site setup wizard',
        'Reduce onboarding calls per customer from 4 to 1',
      ],
    },
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

  tasks_by_quarter = quarters.each_with_object({}) do |quarter, memo|
    content = quarter[:current] ? squad[:current] : squad[:history][quarter[:index]]

    okr = Okr.find_or_create_by!(name: "#{squad[:name]} squad OKR — #{quarter[:label]}", user: po) do |o|
      o.start_date = quarter[:start_date]
      o.end_date = quarter[:end_date]
      o.approved = true
      o.objectives_attributes = [{
        name: content[:objective],
        user_id: po.id,
        key_results_attributes: content[:key_results].map { |kr| { name: kr, user_id: po.id } },
      }]
    end

    memo[quarter[:current] ? :current : quarter[:index]] = okr.key_results.map.with_index do |kr, idx|
      assignee = members[idx] || po
      task = Task.find_or_create_by!(name: "#{squad[:name]} (#{quarter[:label]}): #{kr.name}", project: sitepeg) do |t|
        t.description = "Delivery task for the #{squad[:name]} squad's key result: #{kr.name}"
        t.team = team
        t.user = assignee
        t.start_date = quarter[:start_date]
        t.end_date = [quarter[:start_date] + 3.weeks, quarter[:end_date]].min
        t.priority = idx.zero? ? 'high' : 'medium'
      end
      TaskKeyResult.find_or_create_by!(task: task, key_result: kr)

      # Work logs can't be backdated (WorkLog only allows the last 6 days), so
      # a closed-out quarter is represented by task status instead: completed
      # (and backdated) when the OKR was achieved, left active/overdue when
      # it was missed.
      if !quarter[:current] && content[:achieved] && task.status == 'active'
        task.update!(status: 'completed')
        task.update_column(:completed_on, quarter[:end_date] - (3 + idx).days)
      end

      task
    end
  end

  { team: team, po: po, members: members, tasks_by_quarter: tasks_by_quarter }
end

current_tasks = squads_seeded.first[:tasks_by_quarter][:current]
current_tasks.first.update!(status: 'completed') if current_tasks.first.status == 'active'

# --- A handful of work logs on this quarter's tasks, so recent activity ----
# has something to show (WorkLog dates can't be more than 6 days old).
WorkLog.find_or_create_by!(task: squads_seeded[0][:tasks_by_quarter][:current].first, user: squads_seeded[0][:po], date: Date.today) do |log|
  log.name = 'Modelled variance calc against 3 pilot sites'
  log.minutes = 120
end
WorkLog.find_or_create_by!(task: squads_seeded[1][:tasks_by_quarter][:current].first, user: squads_seeded[1][:members].first, date: Date.today) do |log|
  log.name = 'Field-tested offline sync in a 4G dead zone'
  log.minutes = 75
end
WorkLog.find_or_create_by!(task: squads_seeded[2][:tasks_by_quarter][:current].first, user: squads_seeded[2][:po], date: Date.today) do |log|
  log.name = 'Mapped the current onboarding call script'
  log.minutes = 60
end
