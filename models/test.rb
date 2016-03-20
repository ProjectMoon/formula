require 'ohm'

module MyModule
  class Model1 < Ohm::Model
    attribute :name
    index :name
    collection :model2_collection, :"::MyModule::Model2"
  end

  class Model2 < Ohm::Model
    reference :model1, :"::MyModule::Model1" # has-a
    reference :model3, :"::MyModule::Model3" # belongs-to
    attribute :thing
  end

  class Model3 < Ohm::Model
    collection :model2_collection, :"::MyModule::Model2"
  end
end

m1 = MyModule::Model1.create(name: 'MyModel')
m3 = MyModule::Model3.create
m2 = MyModule::Model2.create(thing: 'thingy', model1: m1, model3: m3)

m1.save
m2.save
m3.save

m3 = MyModule::Model3[1]
m1 = MyModule::Model1[1]

puts m1.model2_collection.size
puts m1.model2_collection.each { |m| puts m.thing }

puts m3.model2_collection.size
puts m3.model2_collection[0].nil?
