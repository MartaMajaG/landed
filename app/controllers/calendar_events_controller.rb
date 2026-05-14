class CalendarEventsController < ApplicationController
  before_action :authenticate_user!

  def ics
    name = params[:name]
    date = params[:date]

    cal = <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Landed//EN
      BEGIN:VEVENT
      UID:#{SecureRandom.uuid}@landed
      DTSTAMP:#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}
      DTSTART;VALUE=DATE:#{date.gsub('-', '')}
      DTEND;VALUE=DATE:#{date.gsub('-', '')}
      SUMMARY:#{name}
      END:VEVENT
      END:VCALENDAR
    ICS

    send_data cal,
              filename: "#{name.parameterize}.ics",
              type: "text/calendar",
              disposition: "attachment"
  end
end
