class User < ApplicationRecord
  has_merit

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  has_many :lfg_posts, dependent: :destroy

  acts_as_voter     # relationship :votes will be obscured by the same named relationship from acts_as_voteable :(
  acts_as_voteable
  serialize :character_data

  def get_character_data 
    puts "in model: #{self}"
    FetchCharacterDataJob.perform_later(self)
  end
end
