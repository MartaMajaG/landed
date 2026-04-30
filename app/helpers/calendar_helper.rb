module CalendarHelper
  def calendar_days(date)
    start_date = date.beginning_of_month.beginning_of_week(:monday)
    end_date   = date.end_of_month.end_of_week(:monday)

    (start_date..end_date).to_a
  end
end
