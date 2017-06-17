module GrooveIssuesHelper
  TYPE_DUE_OVER   = "due_over"
  TYPE_DUE_TODAY  = "due_today"
  TYPE_DUE_FUTURE = "due_future"
  TYPE_DUE_NEAR7  = "due_near7"
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
    end
  end
  
  # get issues count
  def groove_count_issues(grouped_issues)
    count = 0
    grouped_issues.each() { |key, issues| count += issues.count }
    count
  end
  
  # get issues total extimated hours
  def groove_total_estimated_hour_issues(issues)
    hours = 0
    issues.each() { |issue| hours += issue.estimated_hours if issue.estimated_hours }
    hours
  end
  
  # get issues average ratio
  def groove_average_ratio_issues(issues)
    ratio = 0
    issues.each() { |issue| ratio += issue.done_ratio }
    (ratio / issues.count)
  end
  
  private
  
  #get issues due over
  def groove_issues_due_over
    issues = Issue.visible.open.
      where("issues.assigned_to_id = ? AND issues.due_date < ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)", User.current.id, User.current.today).
      order("#{Project.table_name}.name ASC, issues.done_ratio DESC").
      to_a.
      group_by { |issue| {:project => issue.project, :version => issue.fixed_version} }
    issues
  end
  
  #get issues due today
  def groove_issues_due_today
    issues = Issue.visible.open.
      where("issues.assigned_to_id = ? AND issues.due_date = ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)", User.current.id, User.current.today).
      order("#{Project.table_name}.name ASC, issues.done_ratio DESC").
      to_a.
      group_by { |issue| {:project => issue.project, :version => issue.fixed_version} }
    issues
  end
  
  #get issues due future
  def groove_issues_due_future
    issues = Issue.visible.open.
      where("issues.assigned_to_id = ? AND issues.due_date > ? AND (issues.parent_id <> issues.id OR issues.parent_id is null)", User.current.id, User.current.today).
      order("#{Project.table_name}.name ASC, issues.done_ratio DESC").
      to_a.
      group_by { |issue| {:project => issue.project, :version => issue.fixed_version} }
    issues
  end
  
  #get issues due future
  def groove_issues_due_near7
    issues = Issue.visible.open.
      where("issues.assigned_to_id = ? AND (issues.due_date > ? AND issues.due_date <= ?) AND (issues.parent_id <> issues.id OR issues.parent_id is null)", User.current.id, User.current.today, User.current.today+7).
      order("#{Project.table_name}.name ASC, issues.done_ratio DESC").
      to_a.
      group_by { |issue| {:project => issue.project, :version => issue.fixed_version} }
    issues
  end
end