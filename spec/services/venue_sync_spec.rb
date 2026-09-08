require "rails_helper"

RSpec.describe VenueSync do
  describe "#call" do
    it "creates a venue that doesn't exist yet" do
      payload = [
        { "id" => "VEN-01", "name" => "Grand Cinema", "address" => "12 Main Street", "capacity" => 320 }
      ]

      expect { VenueSync.new(payload).call }.to change(Venue, :count).by(1)

      venue = Venue.find_by(external_id: "VEN-01")
      expect(venue).to have_attributes(
        name: "Grand Cinema",
        address: "12 Main Street",
        capacity: 320
      )
    end

    it "updates an existing venue by external id when the upstream name changes" do
      create(
        :venue,
        external_id: "VEN-03",
        name: "City Gallery Screening Room",
        address: "1 Museum Square",
        capacity: 90
      )

      payload = [
        { "id" => "VEN-03", "name" => "City Gallery Auditorium", "address" => "1 Museum Square", "capacity" => 110 }
      ]

      expect { VenueSync.new(payload).call }.not_to change(Venue, :count)

      venue = Venue.find_by!(external_id: "VEN-03")
      expect(venue).to have_attributes(
        name: "City Gallery Auditorium",
        address: "1 Museum Square",
        capacity: 110
      )
    end

    it "does not create duplicates when run more than once" do
      payload = [
        { "id" => "VEN-01", "name" => "Grand Cinema", "address" => "12 Main Street", "capacity" => 320 },
        { "id" => "VEN-02", "name" => "Riverside Cinema", "address" => "4 Quay Road", "capacity" => 180 }
      ]

      expect do
        VenueSync.new(payload).call
        VenueSync.new(payload).call
      end.to change(Venue, :count).by(2)
    end
  end
end
