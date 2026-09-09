class ScreeningsController < ApplicationController
  def index
    @venues = Venue.order(:name)
    @screenings = ScreeningsQuery.new(params).call
  end
end
