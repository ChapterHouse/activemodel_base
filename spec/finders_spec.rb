require 'spec_helper'

class FinderTest < ActiveModel::Base

  attribute :value, :type => :integer, :id => true
  attribute :name, :type => :string, :id => true
  attribute :description
  attribute :helper, :type => :integer, :finder_aid => true
  
  Names=["apple", "bannana", "cantaloupe", "date", "x"]
  @@all = []

  def self.all(attributes_hash={})
    if @@all.empty?
      FinderTest::Names.size.times do |value|
        FinderTest::Names.each do |name|
          @@all << new(:value => value, :name => name, :description => value.even? ? "this is an even description" : "this is an odd description")
        end
      end
    end
    # For test purposes we do something silly here.
    helper_limit = (attributes_hash[:helper] || 0) - 1

    @@all[0..helper_limit]
  end

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
  end

end

describe ActiveModel::Finders do

  it "should provide a count" do
    FinderTest.count.should equal(FinderTest::Names.size * FinderTest::Names.size)
  end
  
  it "should provide a size" do
    FinderTest.count.should equal(FinderTest::Names.size * FinderTest::Names.size)
  end
  
  it "should provide the first item" do
    FinderTest.first.should equal(FinderTest.class_variable_get(:@@all).first)
  end
  
  it "should provide the last item" do
    FinderTest.last.should equal(FinderTest.class_variable_get(:@@all).last)
  end
  
  it "should provide random items" do
    x = FinderTest.random
    y = x
    i = 0
    while i < 1000 && y == x do
      i += 1
      y = FinderTest.random
    end
    y.should_not equal(x)
  end
  
  it "should be findable by id" do
    FinderTest.should respond_to(:find_by_id)
  end
  
  it "should find from an id" do
    (FinderTest.find("bannana_3") rescue nil).should be_an_instance_of(FinderTest)
  end
  
  it "should throw an exception if the id is not found" do
    expect{ FinderTest.find("rasberry_12") }.to raise_error(ActiveModel::RecordNotFound)
  end
  
  it "should NOT throw an exception if using find_by_id and the record is not found" do
    expect{ FinderTest.find_by_id("rasberry_12") }.to_not raise_error(ActiveModel::RecordNotFound)
  end
  
  it "should find one by a single attribute" do
    FinderTest.find_by_name("bannana").should be_an_instance_of(FinderTest)
  end
  
  it "should find many by a single attribute" do
    FinderTest.find_all_by_name("bannana").should be_an_instance_of(Array)
  end
  
  it "should find a subset of all items available with a single attribute" do
    FinderTest.find_all_by_name("bannana").size.should equal(FinderTest::Names.size)
  end
  
  it "should find one by multiple attributes" do
    FinderTest.find_by_name_and_description("bannana", "this is an even description").should be_an_instance_of(FinderTest)
  end
  
  it "should find many by multiple attributes" do
    FinderTest.find_all_by_name_and_description("bannana", "this is an even description").should be_an_instance_of(Array)
  end
  
  it "should find a subset of all items available with a multiple attributes" do
    FinderTest.find_all_by_name_and_description("bannana", "this is an even description").size.should equal((FinderTest::Names.size / 2.0).round)
  end
  
  it "should find a subset if only using the finder aid" do
    FinderTest.find_all_by_helper(7).size.should equal(7)
  end
  
  it "should automatically convert search values before the search" do
    FinderTest.find_by_value("1").should be_an_instance_of(FinderTest)
  end

end
