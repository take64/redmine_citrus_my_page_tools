module CitrusMyPageRenderHelper
  # css method ratio
  def style_ratio(issue)
    ratio = issue.done_ratio
    color = "color:#333333;"
    color = "color:#CCCCCC;" if ratio == 100
    color = "color:#999999;" if ratio >= 50 && ratio < 100
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
  
  # task rendering
  def render_groove_task_progress(issues, day)
    count_remaining = count_task_remaining(issues)
    count_completed = count_task_completed(issues)
    # render tasks
    if count_remaining == 0
      if count_completed == 0
        render_tasks_none
      else
        render_tasks_all_completed(day.cwday)
      end
    elsif count_remaining > 0
      if count_completed == 0
        render_tasks_not_active(day.cwday)
      else
        render_tasks_are_left(count_remaining)
      end
    end
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