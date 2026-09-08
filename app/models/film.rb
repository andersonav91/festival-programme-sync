class Film < ApplicationRecord
  has_many :screenings, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :runtime, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :year, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
