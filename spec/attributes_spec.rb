require 'spec_helper'

class CustomValueTester

  attr_accessor :value

  def initialize(new_value)
    @value = new_value
  end

  def to_custom
    {value => value}
  end
  
end

class AttributeTest < ActiveModel::Base

  attribute :integer_value, :type => :integer, :id => true
  attribute :float_value, :type => :float
  attribute :string_value, :type => :string, :id => true
  attribute :date_value, :type => :date
  attribute :datetime_value, :type => :datetime
  attribute :generic_value
  attribute :custom_value, :type => :custom
  attribute :read_only_value, :readonly => true
  
end

class AttributeAllowNilTest < ActiveModel::Base
  attribute :nonnillable, :allow_nil => false
  attribute :nillable
end

describe ActiveModel::Attributes do

  it "should convert a value to integer" do
    ActiveModel::Attributes.convert_to(:integer, "1").should be_an_instance_of(Fixnum)
  end

  it "should convert a value to float" do
    ActiveModel::Attributes.convert_to(:float, "1.0").should be_an_instance_of(Float)
  end

  it "should convert a value to string" do
    ActiveModel::Attributes.convert_to(:string, 1).should be_an_instance_of(String)
  end

  it "should convert a value to date" do
    ActiveModel::Attributes.convert_to(:date, Date.today.to_s).should be_an_instance_of(Date)
  end

  it "should convert a value to datetime" do
    ActiveModel::Attributes.convert_to(:datetime, DateTime.now.to_s).should be_an_instance_of(DateTime)
  end

  it "should do no conversions on the value" do
    value = {:a => 1, :b => 2, :c => 3}
    ActiveModel::Attributes.convert_to(nil, value).should.equal?(value)
  end

  it "should convert a value to a custom type" do
    value = CustomValueTester.new("test")
    ActiveModel::Attributes.convert_to(:custom, value).should == value.to_custom
  end

  it "should allow assignment during creation" do
    test = AttributeTest.new(:generic_value => "test")
    test.generic_value.should == "test"
  end

  it "should allow assignment after creation" do
    test = AttributeTest.new
    test.generic_value = "test"
    test.generic_value.should == "test"
  end

  it "should NOT be able to assign a read only attribute after initialization" do
    test = AttributeTest.new(:read_only_value => "test")
    expect{ test.read_only_value = "" }.to raise_error(NoMethodError)
  end

  it "should have an implicite id field" do
    test = AttributeTest.new
    
  end

  it "should convert integer attributes to integer after save" do
    test = AttributeTest.new(:integer_value => "1")
    test.save
    test.integer_value.should == 1
  end

  it "should convert float attributes to float after save" do
    test = AttributeTest.new(:float_value => "1.1")
    test.save
    test.float_value.should == 1.1
  end

  it "should convert string attributes to string after save" do
    test = AttributeTest.new(:string_value => 1)
    test.save
    test.string_value.should == "1"
  end

  it "should convert date attributes to date after save" do
    date = Date.today
    test = AttributeTest.new(:date_value => date.to_s)
    test.save
    test.date_value.should == date
  end

  it "should convert datetime attributes to datetime after save" do
    datetime = DateTime.parse(DateTime.now.to_s)
    test = AttributeTest.new(:datetime_value => datetime.to_s)
    test.save
    test.datetime_value.should == datetime
  end

  it "should NOT convert generic attributes after save" do
    binding = Kernel.binding
    test = AttributeTest.new(:generic_value => binding)
    test.save
    test.generic_value.should == binding
  end

  it "should convert custom type attributes to the requested type after save" do
    custom = CustomValueTester.new("test")
    test = AttributeTest.new(:custom_value => custom)
    test.save
    test.custom_value.should == custom.to_custom
  end

  it "should NOT be persisted" do
    test = AttributeTest.new
    test.persisted?.should == false
  end

  it "should compare against equal attributes" do
    test1 = AttributeTest.new(:string_value => "test", :integer_value => 1)
    test2 = AttributeTest.new(:string_value => "test", :integer_value => 1)
    test1.should == test2
  end

  it "should compare against unequal attributes" do
    test1 = AttributeTest.new(:string_value => "test", :integer_value => 1, :id => 1)
    test2 = AttributeTest.new(:string_value => "test", :integer_value => 1, :id => 2)
    test1.should_not == test2
  end

  it "should autocalculate the id" do
    test = AttributeTest.create(:integer_value => 1, :string_value => "test")
    test.id.should == "1_test"
  end

  it "should recalculate the id" do
    test = AttributeTest.create(:integer_value => 1, :string_value => "test")
    test.integer_value = 2
    test.string_value = "be"
    test.save
    test.id.should == "2_be"
  end

  it "should not allow nil" do
#    pending "determine where to test this"
  end

  it "should allow nil" do
#    pending "determine where to test this"
  end

end
