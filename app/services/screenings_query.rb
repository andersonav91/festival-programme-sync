class ScreeningsQuery
  def initialize(params)
    @params = params
  end

  def call
    scope = Screening.includes(:film, :venue).order(:starts_at)
    scope = filter_by_venue(scope)
    scope = filter_by_date(scope)
    filter_by_title(scope)
  end

  private

  attr_reader :params

  def filter_by_venue(scope)
    return scope if params[:venue_id].blank?

    scope.where(venue_id: params[:venue_id])
  end

  def filter_by_date(scope)
    return scope if params[:date].blank?

    date = parse_date(params[:date])
    return scope unless date

    scope.where(starts_at: date.all_day)
  end

  def filter_by_title(scope)
    return scope if params[:q].blank?

    scope.joins(:film).where("films.title ILIKE ?", "%#{sanitize_query(params[:q])}%")
  end

  def parse_date(value)
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def sanitize_query(value)
    ActiveRecord::Base.sanitize_sql_like(value.strip)
  end
end
