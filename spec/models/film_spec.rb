require "rails_helper"

RSpec.describe Film, type: :model do
  subject(:film) { build(:film) }

  it { is_expected.to be_valid }

  it "requires an external id" do
    film.external_id = nil

    expect(film).not_to be_valid
  end

  it "requires a title" do
    film.title = nil

    expect(film).not_to be_valid
  end

  it "requires external ids to be unique" do
    create(:film, external_id: "FILM-001")
    film.external_id = "FILM-001"

    expect(film).not_to be_valid
  end

  it "rejects invalid runtimes" do
    film.runtime = 0

    expect(film).not_to be_valid
  end

  it "rejects invalid years" do
    film.year = -1

    expect(film).not_to be_valid
  end

  it "destroys its screenings when deleted" do
    persisted_film = create(:film)
    create(:screening, film: persisted_film)

    expect { persisted_film.destroy! }.to change(Screening, :count).by(-1)
  end
end
