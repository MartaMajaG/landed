class AlertsController < ApplicationController
  def index
    @feed = AlertsFeed.new(current_user)
  end
end
