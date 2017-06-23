module GrooveIssuesHelper
  TYPE_DUE_OVER         = 'due_over'
  TYPE_DUE_TODAY        = 'due_today'
  TYPE_DUE_FUTURE       = 'due_future'
  TYPE_DUE_NEAR7        = 'due_near7'
  TYPE_NEGLECTED_NOTYET = 'neglected_notyet'
  TYPE_NEGLECTED_SOON   = 'neglected_soon'
  # get issues
  def groove_issues(type)
    case type
    when TYPE_DUE_OVER then
      groove_issues_due_over
    when TYPE_DUE_TODAY then
      groove_issues_due_today
    when TYPE_DUE_FUTURE then
      groove_issues_due_future
    when TYPE_DUE_NEAR7 then
      groove_issues_due_near7
    when TYPE_NEGLECTED_NOTYET then
      groove_issues_neglected_notyet
    when TYPE_NEGLECTED_SOON then
      groove_issues_neglected_soon
    end
  end

  # get issues count
  def groove_count_issues(grouped_issues)
    count = 0
    grouped_issues.each_value do |issues|
      count += issues.count
    end
    count
  end

  # get issues total extimated hours
  def groove_total_estimated_hour_issues(issues)
    hours = 0
    issues.each do |issue|
      hours += issue.estimated_hours if issue.estimated_hours
    end
    hours
  end

  # get issues average ratio
  def groove_average_ratio_issues(issues)
    ratio = 0
    issues.each do |issue|
      ratio += issue.done_ratio
    end
    (ratio / issues.count)
  end

  private

  # get issues due over
  def groove_issues_due_over
    groove_issues_due('issues.assigned_to_id = ? AND issues.due_date < ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)', User.current.id, User.current.today)
  end

  # get issues due today
  def groove_issues_due_today
    groove_issues_due('issues.assigned_to_id = ? AND issues.due_date = ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)', User.current.id, User.current.today)
  end

  # get issues due future
  def groove_issues_due_future
    groove_issues_due('issues.assigned_to_id = ? AND issues.due_date > ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)', User.current.id, User.current.today)
  end

  # get issues due future
  def groove_issues_due_near7
    groove_issues_due('issues.assigned_to_id = ? AND (issues.due_date > ? AND issues.due_date <= ?) AND (issues.parent_id <> issues.id OR issues.parent_id is null)', User.current.id, User.current.today, User.current.today + 7)
  end

  # get issues neglected not yet
  def groove_issues_neglected_notyet
    groove_issues_due('issues.assigned_to_id = ? AND issues.due_date < ? AND (issues.parent_id <> issues.id OR issues.parent_id is null) AND done_ratio = 0', User.current.id, User.current.today)
  end

  # get issues neglected soon
  def groove_issues_neglected_soon
    groove_issues_due('issues.assigned_to_id = ? AND issues.due_date < ? AND (issues.parent_id <> issues.id OR issues.parent_id is null) AND done_ratio >= 50', User.current.id, User.current.today)
  end

  # get issue due
  def groove_issues_due(where, *condition)
    Issue.visible.open.
      where(where, *condition).
      order("#{Project.table_name}.name ASC, issues.done_ratio DESC").
      to_a.
      group_by { |issue| {project: issue.project, version: issue.fixed_version} }
  end
end
