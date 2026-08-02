class Provider < ApplicationRecord
  has_many :chats, dependent: :nullify

  enum :contact_status, { pending: 0, found: 1, not_found: 2 }

  validates :name, presence: true
  validates :normalized_name, presence: true, uniqueness: true

  before_validation :set_normalized_name

  def self.find_or_create_for(raw_name)
    normalized = normalize(raw_name)
    find_by(normalized_name: normalized) || create!(name: raw_name)
  end

  def self.normalize(raw_name)
    raw_name.to_s.strip.downcase.gsub(/\s+/, " ")
  end

  def stale?
    return true if looked_up_at.nil?

    looked_up_at < 90.days.ago
  end

  private

  def set_normalized_name
    self.normalized_name = self.class.normalize(name)
  end
end
