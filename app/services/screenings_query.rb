class ScreeningsQuery
  DEFAULT_PAGE = 1
  DEFAULT_SORT = "starts"
  DEFAULT_DIRECTION = "asc"
  DIRECTIONS = %w[asc desc].freeze
  PER_PAGE = 15
  SORTS = {
    "film" => "films.title",
    "venue" => "venues.name",
    "starts" => "screenings.starts_at",
    "status" => "screenings.status"
  }.freeze

  Result = Struct.new(
    :records,
    :page,
    :per_page,
    :total_count,
    :total_pages,
    :sort,
    :direction,
    keyword_init: true
  ) do
    def previous_page
      page > 1 ? page - 1 : nil
    end

    def next_page
      page < total_pages ? page + 1 : nil
    end
  end

  def initialize(params, paginated: true)
    @params = params
    @paginated = paginated
  end

  def call
    scope = Screening.left_joins(:film, :venue).includes(:film, :venue)
    scope = filter_by_venue(scope)
    scope = filter_by_date(scope)
    scope = filter_by_title(scope)
    scope = apply_sort(scope)

    total_count = scope.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = current_page(total_pages)
    records = paginated? ? scope.limit(PER_PAGE).offset((page - 1) * PER_PAGE) : scope

    Result.new(
      records: records,
      page: page,
      per_page: PER_PAGE,
      total_count: total_count,
      total_pages: total_pages,
      sort: sort_key,
      direction: sort_direction
    )
  end

  private

  attr_reader :params

  def paginated?
    @paginated
  end

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

    scope.where("films.title ILIKE ?", "%#{sanitize_query(params[:q])}%")
  end

  def apply_sort(scope)
    scope.order(Arel.sql("#{SORTS.fetch(sort_key)} #{sort_direction.upcase}"), id: :asc)
  end

  def current_page(total_pages)
    page = params[:page].to_i
    page = DEFAULT_PAGE if page < DEFAULT_PAGE
    [ page, total_pages ].min
  end

  def sort_key
    SORTS.key?(params[:sort].to_s) ? params[:sort].to_s : DEFAULT_SORT
  end

  def sort_direction
    DIRECTIONS.include?(params[:direction].to_s) ? params[:direction].to_s : DEFAULT_DIRECTION
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
