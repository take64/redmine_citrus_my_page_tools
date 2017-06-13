module GrooveCalendarHelper
  # calendar
  def groove_calendars
    week_list = [0, 7]
    if User.current.today.cwday <= 3
      week_list.unshift(-7)
    else
      week_list.push(14)
    end
    calendars = []
    for add_day in week_list do
      calendar = Redmine::Helpers::Calendar.new(User.current.today+add_day, current_language, :week)
      calendar.events = calendar_items(calendar.startdt, calendar.enddt)
      calendars << calendar
    end
    calendars
  end

  # time entry
  def groove_time_entries(first_day)
    time_entries = TimeEntry.where("#{TimeEntry.table_name}.user_id = ? AND #{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", User.current.id, first_day, User.current.today).
      joins(:activity, :project).
      references(:issue => [:tracker, :status]).
      includes(:issue => [:tracker, :status]).
      order("#{TimeEntry.table_name}.spent_on DESC, #{Project.table_name}.name ASC, #{Tracker.table_name}.position ASC, #{Issue.table_name}.id ASC").
      to_a.
      group_by(&:spent_on)
    time_entries
  end

  # groove estimated hours
  def groove_estimated_hours(calendars, events)
    estimated_hours = {}
    week_estimated_hours = Array.new(calendars.length, 0)
    for day in calendars.first.startdt..calendars.last.enddt do
      for issue in events[day] do
        # filter
        next unless issue.is_a? Issue
        next unless issue.estimated_hours
        # logic
        hour = (issue.estimated_hours / (issue.working_duration + 1))
        estimated_hours[day] = nvl_zero(estimated_hours[day]) + hour
        week_estimated_hours[calendars.index(find_calendar(calendars, day))] += hour
      end
    end
    {
      'estimated_hours' => estimated_hours,
      'week_estimated_hours' => week_estimated_hours,
    }
  end
  
  # events
  def groove_events(calendars)
    events = {}
    for day in calendars.first.startdt..calendars.last.enddt do
      events[day] = find_calendar(calendars, day).events_on(day)
      events[day].sort! do |a, b|
        ret = ((a.working_duration) <=> (b.working_duration)) * -1
        ret = ((a.project) <=> (b.project)) if ret == 0
        ret
      end
    end
    events
  end

  # entry hours
  def groove_entry_hours(calendars, time_entries)
    entry_hours = {}
    week_entry_hours = Array.new(calendars.length, 0)
    for day in calendars.first.startdt..calendars.last.enddt do
      # filter
      next unless time_entries[day]
      # logic
      for time_entry in time_entries[day] do
        # filter
        next unless time_entry
        # logic
        entry_hours[day] = nvl_zero(entry_hours[day]) + time_entry.hours
        week_entry_hours[calendars.index(find_calendar(calendars, day))] += time_entry.hours
      end
    end
    {
      'entry_hours' => entry_hours,
      'week_entry_hours' => week_entry_hours,
    }
  end
  
  # task rendering
  def render_groove_task_progress(issues, day)
    count_remaining = count_task_remaining(issues)
    count_completed = count_task_completed(issues)
    cwday = day.cwday
    # render tasks
    if (count_remaining == 0 && count_completed == 0)
      render_tasks_none
    elsif (count_remaining == 0 && count_completed != 0)
      render_tasks_all_completed(cwday)
    elsif (count_remaining > 0 && count_completed == 0)
      render_tasks_not_active(cwday)
    elsif (count_remaining > 0)
      render_tasks_are_left(count_remaining)
    end
  end
  
  # css method ratio
  def style_ratio(issue)
    ratio = issue.done_ratio
    color = "color:#333333;"
    color = "color:#CCCCCC;" if ratio == 100
    color = "color:#999999;" if ratio >= 75 && ratio < 100
    color = "color:#999999;" if ratio >= 50 && ratio < 75
    color = "color:#666666;" if ratio >= 25 && ratio < 50
    color
  end

  # css method week
  def style_week(day)
    style = "background-color:#F9F9F9;"
    style = "background-color:#EE9999;color:#FFFFFF;" if day.wday == 0
    style = "background-color:#9999EE;color:#FFFFFF;" if day.wday == 6
    style
  end

  # util method
  def nvl_zero(value)
    ret = 0
    ret = value if value
    ret
  end
  
  private
  
  # find calendar
  def find_calendar(calendars, day)
    calendar = calendars.find { |item| (item.startdt <= day && item.enddt >= day) }
    calendar
  end
  
  # count remaining task
  def count_task_remaining(issues)
    count = 0
    issues.each do |issue|
      # filter
      next unless issue.is_a?(Issue)
      # logic
      count += 1 unless issue.closed?
    end
    count
  end
  
  # count completed task
  def count_task_completed(issues)
    count = 0
    issues.each do |issue|
      # filter
      next unless issue.is_a?(Issue)
      # logic
      count += 1 if issue.closed?
    end
    count
  end
  
  # render none tasks
  def render_tasks_none
    "task schedule none.".html_safe
  end
  
  # render all completed tasks
  def render_tasks_all_completed(cwday)
    color = "#6666CC" if cwday <= 5
    color = "#FFFFFF" if cwday >= 6
    "<span style='font-weight:bold;color:#{color};'>task All Completed.</span>".html_safe
  end
  
  # render not active tasks
  def render_tasks_not_active(cwday)
    color = "#CC6666" if cwday <= 5
    color = "#FFFFFF" if cwday >= 6
    "<span style='font-weight:bold;color:#{color};'>task Not Active...</span>".html_safe
  end
  
  # render are left tasks
  def render_tasks_are_left(count_remaining)
    "<span style='font-weight:bold;'>task are left. ( #{count_remaining} )</span>".html_safe
  end
end