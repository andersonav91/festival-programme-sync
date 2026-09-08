class Venue < ApplicationRecord
  has_many :screenings, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
