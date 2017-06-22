# Grrove Calendar Helper
module GrooveCalendarHelper
  # calendar
  def groove_calendars
    week_list = [0, 7]
    week_list.unshift(-7) if User.current.today.cwday <= 3
    week_list.push(14)    if User.current.today.cwday >= 4
    calendars = []
    week_list.each {|add_day|
      calendar = Redmine::Helpers::Calendar.new(User.current.today + add_day, current_language, :week)
      calendar.events = calendar_items(calendar.startdt, calendar.enddt)
      calendars << calendar
    }
    calendars
  end

  # time entry
  def groove_time_entries(first_day)
    TimeEntry.where("#{TimeEntry.table_name}.user_id = ? AND #{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", User.current.id, first_day, User.current.today).
      joins(:activity, :project).
      references(:issue => [:tracker, :status]).
      includes(:issue => [:tracker, :status]).
      order("#{TimeEntry.table_name}.spent_on DESC, #{Project.table_name}.name ASC, #{Tracker.table_name}.position ASC, #{Issue.table_name}.id ASC").
      to_a.
      group_by(&:spent_on)
  end

  # groove estimated hours
  def groove_estimated_hours(calendars, events)
    estimated_hours = {}
    week_estimated_hours = Array.new(calendars.length, 0)
    (calendars.first.startdt..calendars.last.enddt).each {|day|
      events[day].each {|issue|
        # filter
        next unless issue.is_a? Issue
        next unless issue.estimated_hours
        # logic
        hour = (issue.estimated_hours / (issue.working_duration + 1))
        estimated_hours[day] = nvl_zero(estimated_hours[day]) + hour
        if issue.working_duration > 1 && day == issue.start_date
          (1..(issue.working_duration - 1)).each {|duration|
            duration_day = day + duration
            estimated_hours[duration_day] = nvl_zero(estimated_hours[duration_day]) + hour
          }
        end
        week_estimated_hours[calendars.index(find_calendar(calendars, day))] += hour
      }
    }
    {
      'estimated_hours' => estimated_hours,
      'week_estimated_hours' => week_estimated_hours,
    }
  end

  # events
  def groove_events(calendars)
    events = {}
    (calendars.first.startdt..calendars.last.enddt).each {|day|
      events[day] = find_calendar(calendars, day).events_on(day)
      events[day].sort! do |a, b|
        ret = ((a.working_duration) <=> (b.working_duration)) * -1
        ret = ((a.project) <=> (b.project)) if ret == 0
        ret
      end
    }
    events
  end

  # entry hours
  def groove_entry_hours(calendars, time_entries)
    entry_hours = {}
    week_entry_hours = Array.new(calendars.length, 0)
    (calendars.first.startdt..calendars.last.enddt).each {|day|
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
    }
    {
      'entry_hours' => entry_hours,
      'week_entry_hours' => week_entry_hours,
    }
  end

  # util method
  def nvl_zero(value)
    ret = 0
    ret = value if value
    ret
  end

  # find calendar
  def find_calendar(calendars, day)
    calendars.find { |item| (item.startdt <= day && item.enddt >= day) }
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
  # @param [Issue] issues
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
end
