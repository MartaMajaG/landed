class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :checklist_item

  # Allows one attached document (PDF/image)for processing. For images, creates an AI-ready JPEG (quality 85), resized and auto-oriented for smaller, efficient uploads.
  has_one_attached :document do |attachable|
    attachable.variant :ai_ready, resize_to_limit: [2048, 2048], format: :jpeg, saver: { quality: 85 }
  end
end
