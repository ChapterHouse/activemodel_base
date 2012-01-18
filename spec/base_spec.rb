require 'spec_helper'

describe ActiveModel::Base do

  class BaseTester < ActiveModel::Base

    @@testerStore = []

    def self.save(record)
      @@testerStore << self
      true
    end

  end

  class NoSaveTester < ActiveModel::Base

    def self.save(record)
      false
    end

  end

  class ExplodingTester < ActiveModel::Base

    def self.save(record)
      raise "Kaboom!!!"
    end

  end

  describe "base" do
    
    it "should start as a new record" do
      test = BaseTester.new
      test.new_record?.should be_true
    end
    
    it "should mark a new_record as false when saved" do
      test = BaseTester.new
      test.save
      test.new_record?.should be_false
    end

    it "should mark new_record as false when created" do
      test = BaseTester.new
      test.save
      test.new_record?.should be_false
    end

    it "should fill in the id when saved" do
      test = BaseTester.new
      test.save
      test.id.should_not be_nil
    end

    it "should revert the id when save fails" do
      test = NoSaveTester.new
      test.save
      test.id.should be_nil
    end

    it "should not set new_record to false when save fails" do
      test = NoSaveTester.new
      test.save
      test.new_record?.should be_true
    end

    it "should not set new_record to true when save fails" do
      test = NoSaveTester.new
      test.instance_variable_set(:@new_record, false)
      test.save
      test.new_record?.should be_false
    end

    it "should revert the id when save raises an exception" do
      test = ExplodingTester.new
      expect{ test.save }.to raise_error
      test.id.should be_nil
    end

    it "should not set new_record to false when save raises an exception" do
      test = ExplodingTester.new
      expect{ test.save }.to raise_error
      test.new_record?.should be_true
    end

    it "should not set new_record to true when save raises an exception" do
      test = ExplodingTester.new
      test.instance_variable_set(:@new_record, false)
      expect{ test.save }.to raise_error
      test.new_record?.should be_false
    end

    it "should start as not read only" do
      test = BaseTester.create
      test.readonly?.should be_false
    end

    it "should be markable as read only" do
      test = BaseTester.create
      test.readonly!
      test.readonly?.should be_true
    end

    it "should not allow a read only record to be saved" do
      test = BaseTester.create
      test.readonly!
      expect{ test.save }.to raise_error(ActiveModel::ReadOnlyRecord)
    end

  end

end
