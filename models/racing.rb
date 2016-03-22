require 'set'
require 'elo'
require 'ohm'
require 'ohm/contrib'

# TODO models cannot be wrapped in a module at the moment.

class Racer < Ohm::Model
  DEFAULT_RATING = 1500

  attribute :name
  attribute :elo_rating
  collection :race_results, :RaceResult
  collection :cars, :Car
  index :name

  # Create a new racer with the default Elo rating if the rating is
  # not specified.
  def self.create(**args)
    args[:elo_rating] = DEFAULT_RATING if !args.has_key?(:elo_rating)
    super(args)
  end

  def car(name)
    cars.select { |car| car.name == name }.first
  end

  def races()
    race_results.map { |result| result.race }.uniq
  end

  def total_points
    race_results.inject(0) { |pts, result| pts + result.points }
  end
end

class Car < Ohm::Model
  include Ohm::DataTypes

  reference :racer, :Racer

  attribute :name
  attribute :type # basic, stock, custom

  attribute :tire_wp, Type::Integer
  attribute :brake_wp, Type::Integer
  attribute :gearbox_wp, Type::Integer
  attribute :body_wp, Type::Integer
  attribute :engine_wp, Type::Integer
  attribute :road_handling_wp, Type::Integer

  attribute :kers, Type::Boolean
  attribute :drs, Type::Boolean

  index :name

  # Creates a new entry for the basic car
  def self.basic_car(racer)
    self.create(
      racer: racer,
      name: 'Basic Car',
      type: :basic,
      tire_wp: -1,
      brake_wp: -1,
      gearbox_wp: -1,
      body_wp: -1,
      engine_wp: -1,
      road_handling_wp: -1,
      kers: false,
      drs: false
    )
  end

  def self.advanced_car(racer)
    self.create(
      racer: racer,
      name: 'Advanced Car',
      type: :advanced,
      tire_wp: 6,
      brake_wp: 3,
      gearbox_wp: 3,
      body_wp: 3,
      engine_wp: 3,
      road_handling_wp: 2,
      kers: false,
      drs: false
    )
  end
end

class RaceResult < Ohm::Model
  include Ohm::DataTypes
  reference :racer, :Racer
  reference :car, :Car
  reference :race, :Race
  attribute :status
  attribute :places, Type::Array
  attribute :highest_place, Type::Integer
  attribute :points, Type::Integer

  # Point scores used in a 10 car race. With less players, only higher
  # values are used. This is OK since the points are used to determine
  # the place for inputs into the Elo system.
  SCORES = [ 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 ]

  # Overridden version of create to calculate highest place and points
  # before insert. Also allows the convenience of specifying the place
  # as a single number if it's not passed in as an array.
  def self.create(**args)
    args[:places] = [ args[:places] ] if !args[:places].is_a? Array
    args[:points] = args[:places].inject(0) { |pts, place| pts += SCORES[place - 1] }
    args[:highest_place] = args[:places].min
    super(args)
  end

  # Determine the standing of a racer in the race based on others. If
  # the racer is tied with another (possible when controlling multiple
  # cars), the highest place is used as a tiebreaker.
  def <=>(other)
    if self.points == other.points
      # for place, we want to minimize (lower is better).
      self.highest_place <=> other.highest_place
    else
      # for points, we want to maximize, not minimize.
      other.points <=> self.points
    end
  end
end

class Race < Ohm::Model
  include Ohm::DataTypes

  attribute :number, Type::Integer
  attribute :date
  attribute :type
  attribute :circuit
  collection :results, :RaceResult

  attr_reader :standings
  attr_reader :racers


  def standings()
    results.sort_by :points, :order => "DESC"
  end

  def racers()
    results.sort().map { |result| result.racer }
  end

  def <<(race_result)
    #results.(race_result)
  end

  def [](i)
    results.sort()[i]
  end

  def racer_in_place(place)
    standings[place - 1].racer
  end

  def standings_not_eliminated
    standings.select { |standing| standing.racer.status != :eliminated }
  end

  # Make sure that the number of places defined on the players matches
  # the number of cars, that no place number is higher than 10, and
  # that the place numbers are all sequential (e.g. not 1st, 2nd,
  # 4th). If it's a multi-car race, make sure everyone has multiple
  # cars.
  def validate()
    # TODO ... later
  end

  # Recursively save every entity in the race.
  def save_all()
    results.each do |result|
      result.racer.save()
      result.save()
    end

    save()
  end
end
