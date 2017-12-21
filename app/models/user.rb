# frozen_string_literal: true

class User < ApplicationRecord
  has_merit

  has_many :lfg_posts, dependent: :destroy
  has_many :characters

  acts_as_voter
  acts_as_voteable
  serialize :character_data

  def get_character_data
    FetchCharacterDataJob.perform_later(self)
  end
end
