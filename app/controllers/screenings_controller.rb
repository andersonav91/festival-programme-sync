class ScreeningsController < ApplicationController
  def index
    @venues = Venue.order(:name)
    @screenings_table_params = screenings_table_params
    @date_filter_value = @screenings_table_params["date"]

    respond_to do |format|
      format.html do
        @pagination = ScreeningsQuery.new(@screenings_table_params).call
        @screenings = @pagination.records
      end

      format.csv do
        screenings = ScreeningsQuery.new(@screenings_table_params, paginated: false).call.records

        send_data(
          ScreeningsCsvExport.new(screenings).call,
          filename: "screenings-#{Time.zone.today.iso8601}.csv",
          type: "text/csv"
        )
      end
    end
  end

  private

  def screenings_table_params
    return {} if params[:clear_filters].present?

    params.permit(:date, :venue_id, :q, :sort, :direction, :page).to_h.tap do |permitted|
      permitted["date"] = Date.current.iso8601 unless permitted.key?("date")
    end
  end
end
