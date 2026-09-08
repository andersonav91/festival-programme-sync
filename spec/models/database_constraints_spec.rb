require "rails_helper"

RSpec.describe "database constraints", type: :model do
  it "enforces unique film external ids at the database level" do
    create(:film, external_id: "FILM-001")

    expect do
      Film.insert!({
        external_id: "FILM-001",
        title: "Duplicate Film",
        created_at: Time.current,
        updated_at: Time.current
      })
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces unique venue external ids at the database level" do
    create(:venue, external_id: "VEN-01")

    expect do
      Venue.insert!({
        external_id: "VEN-01",
        name: "Duplicate Venue",
        created_at: Time.current,
        updated_at: Time.current
      })
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces unique screening external ids at the database level" do
    create(:screening, external_id: "SCR-0001")
    film = create(:film)
    venue = create(:venue)

    expect do
      Screening.insert!({
        external_id: "SCR-0001",
        film_id: film.id,
        venue_id: venue.id,
        starts_at: Time.current,
        status: "scheduled",
        created_at: Time.current,
        updated_at: Time.current
      })
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces screening film foreign keys at the database level" do
    venue = create(:venue)

    expect do
      Screening.insert!({
        external_id: "SCR-0001",
        film_id: -1,
        venue_id: venue.id,
        starts_at: Time.current,
        status: "scheduled",
        created_at: Time.current,
        updated_at: Time.current
      })
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces screening venue foreign keys at the database level" do
    film = create(:film)

    expect do
      Screening.insert!({
        external_id: "SCR-0001",
        film_id: film.id,
        venue_id: -1,
        starts_at: Time.current,
        status: "scheduled",
        created_at: Time.current,
        updated_at: Time.current
      })
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
