module ScreeningsHelper
  def screenings_sort_link(label, sort, pagination)
    sort = sort.to_s
    direction = next_sort_direction(sort, pagination)

    link_to(
      "#{label}#{sort_indicator(sort, pagination)}",
      screenings_path(screenings_table_params.merge(sort: sort, direction: direction, page: 1)),
      data: { turbo_frame: "screenings" },
      class: "inline-flex items-center gap-1 hover:text-gray-900"
    )
  end

  def screenings_page_path(page)
    screenings_path(screenings_table_params.merge(page: page))
  end

  def screenings_export_path
    screenings_path(screenings_table_params.merge(format: :csv))
  end

  def screenings_page_items(pagination)
    pages = [
      1,
      pagination.page - 1,
      pagination.page,
      pagination.page + 1,
      pagination.total_pages
    ].select { |page| page.between?(1, pagination.total_pages) }.uniq.sort

    pages.each_with_object([]) do |page, items|
      items << :gap if items.any? && page > items.last.to_i + 1
      items << page
    end
  end

  private

  def screenings_table_params
    table_params = @screenings_table_params || request.query_parameters
    table_params.slice("date", "venue_id", "q", "sort", "direction").compact_blank
  end

  def next_sort_direction(sort, pagination)
    pagination.sort == sort && pagination.direction == "asc" ? "desc" : "asc"
  end

  def sort_indicator(sort, pagination)
    return "" unless pagination.sort == sort

    pagination.direction == "asc" ? " ^" : " v"
  end
end
