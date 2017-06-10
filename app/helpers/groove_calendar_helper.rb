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
  # groove hours
  def groove_hours(calendars, time_entries)
    estimated_hours = {}
    entry_hours = {}
    events = {}
    week_estimated_hours = []
    week_entry_hours = []
    for calendar in calendars do
      day = calendar.startdt
      week_estimated_hour = 0
      week_entry_hour = 0
      while day <= calendar.enddt
        # estimated_hours
        for issue in calendar.events_on(day) do
          # filter
          next unless issue.is_a? Issue
          next unless issue.estimated_hours
          # logic
          estimated_hours[day] = nvl_zero(estimated_hours[day])
          hour = (issue.estimated_hours / (issue.working_duration + 1))
          estimated_hours[day] = estimated_hours[day] + hour
          week_estimated_hour = week_estimated_hour + hour
        end
        # entry_hours
        if time_entries[day]
          for time_entry in time_entries[day] do
            # filter
            next unless time_entry
            # logic
            entry_hours[day] = nvl_zero(entry_hours[day])
            entry_hours[day] = entry_hours[day] + time_entry.hours
            week_entry_hour = week_entry_hour + time_entry.hours
          end
        end
        # events
        events[day] = calendar.events_on(day)
        events[day].sort! do |a, b|
          ret = ((a.working_duration) <=> (b.working_duration)) * -1
          if ret == 0
            ret = ((a.project) <=> (b.project))
          end
          ret
        end
        # add
        day = day + 1;
      end
      week_estimated_hours << week_estimated_hour
      week_entry_hours << week_entry_hour
    end
    {
      'estimated_hours' => estimated_hours,
      'entry_hours' => entry_hours,
      'events' => events,
      'week_estimated_hours' => week_estimated_hours,
      'week_entry_hours' => week_entry_hours,
    }
  end
  # css method ratio
  def style_ratio(issue)
    ratio = issue.done_ratio
    if ratio == 100
      "color:#CCCCCC;"
    elsif ratio >= 75
      "color:#999999;"
    elsif ratio >= 50
      "color:#999999;"
    elsif ratio >= 25
      "color:#666666;"
    else
      "color:#333333;"
    end
  end
  # css method week
  def style_week(day)
    if day.wday == 0
      "background-color:#EE9999;color:#FFFFFF;"
    elsif day.wday == 6
      "background-color:#9999EE;color:#FFFFFF;"
    else
      "background-color:#F9F9F9;"
    end
  end
  # util method
  def nvl_zero(value)
    if value
      value
    else
      0
    end
  end
end