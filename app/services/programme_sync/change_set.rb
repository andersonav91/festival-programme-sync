class ProgrammeSync
  class ChangeSet
    COUNTERS = %i[
      films_created
      films_updated
      venues_created
      venues_updated
      screenings_created
      screenings_updated
    ].freeze

    attr_accessor(*COUNTERS)

    def initialize
      COUNTERS.each { |counter| public_send("#{counter}=", 0) }
    end

    def record(scope, created:, changed:)
      attribute = if created
        "#{scope}_created"
      elsif changed
        "#{scope}_updated"
      end
      return unless attribute

      public_send("#{attribute}=", public_send(attribute) + 1)
    end

    def merge_into(result)
      COUNTERS.each do |counter|
        result.public_send("#{counter}=", result.public_send(counter) + public_send(counter))
      end
    end
  end
end
