require 'spec_helper'

class Author < ActiveModel::Base

  attribute :name, :type => :string, :id => true

  Names = ["Adam", "Bob", "Charlie", "Diane"]
  @@all = []
  
  def self.all
    Names.each { |name| @@all << new(:name => name) } if @@all.empty?
    @@all
  end 

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
  end

  def self.next_author(author)
    find(Names[Names.index(author.id) + 1])
  end

  def self.reset_all
    @@all = []
  end

end

class Rating < ActiveModel::Base

  attribute :description, :type => :string, :id => true

  Descriptions = ["Excellant", "Great", "Good", "Bad", "BurnIt"]

  @@all = []
  def self.all
    Descriptions.each { |description| @@all << new(:description => description) } if @@all.empty?
    @@all
  end

  def self.reset_all
    @@all = []
  end

end

class GenericRecord < ActiveModel::Base
  
  attribute :value, :type => :integer
  attribute :id, :type => :integer
  
  @@all = []
  def self.all
    5.times { |x| @@all << new(:id => x, :value => x*x) } if @@all.empty?
    @@all
  end

  def self.reset_all
    @@all = []
  end

end

class Post < ActiveModel::Base

  attribute :title, :type => :string, :id => true
  belongs_to :author
  belongs_to :writer, :class_name => "Author"
  belongs_to :rating, :foreign_key => :appreciation_id
  belongs_to :generic_record, :readonly => true 

  @@all = []

  def self.all
    Author.all.each do |author|
      3.times do |x|
        @@all << new(:title => "#{author.name}'s post number #{x}", :author_id => author.id, :writer_id => author.id, :generic_record_id => x)
      end
    end if @@all.empty?
    @@all
  end 

  def self.reset_all
    @@all = []
  end

  def blah
    read_attribute(:title)
  end

end


describe ActiveModel::Associations do

  after(:each) do
    Author.reset_all
    Post.reset_all
    Rating.reset_all
    GenericRecord.reset_all
  end

  describe "#belongs_to" do
 
    context "with no options" do
  
      it "has an association_id attribute" do
        Post.model_attributes.keys.include?(:author_id).should be(true)
      end

      it "has a read association accessor" do
        Post.first.should respond_to(:author)
      end

      it "has a write association accessor" do
        Post.first.should respond_to(:author=)
      end

      it "has an association_id that matches the id of the retrieved association" do
        post = Post.first
        post.author.id.should equal(post.author_id)
      end

      it "changes the association if the association_id changes" do
        post = Post.first
        next_author = Author.next_author(post.author)
        post.author_id = next_author.id
        post.author.should equal(next_author)
      end

      it "changes the association_id if the association changes" do
        post = Post.first
        next_author = Author.next_author(post.author)
        post.author = next_author
        post.author_id.should equal(next_author.id)
      end

      it "allows nil to be set for the association_id" do
        post = Post.first
        post.author_id = nil
        post.should be_valid
      end

      it "allows nil to be set for the association" do
        post = Post.first
        post.author = nil
        post.should be_valid
      end

      it "changes the association to nil if the association_id changes to nil" do
        post = Post.first
        post.author_id = nil
        post.author.should be_nil
      end

      it "changes the association_id to nil if the association changes to nil" do
        post = Post.first
        post.author = nil
        post.author_id.should be_nil
      end

    end

    context "with the class_name option" do
      it "has a normal association_id attribute" do
        Post.model_attributes.keys.should include(:writer_id)
      end

      it "has a normal association accessor" do
        Post.first.should respond_to(:writer)
      end

      it "retrieves the requested class" do
        Post.first.writer.should be_an_instance_of(Author)
      end
    end
    
    context "with the foreign_key option" do
      it "has a different association_id attribute" do
        Post.model_attributes.keys.should include(:appreciation_id)
      end

      it "doesn't have a normal association_id attribute" do
        Post.model_attributes.keys.should_not include(:rating_id)
      end

      it "has a normal association read accessor" do
        Post.first.should respond_to(:rating)
      end

      it "has a normal association write accessor" do
        Post.first.should respond_to(:rating=)
      end
    end

    context "with the readonly option" do
      it "marks the association as read only when set to true" do
        expect{ Post.first.generic_record.save }.to raise_error(ActiveModel::ReadOnlyRecord)
      end
    end

    context "with the allow_nil option" do
      it "marks the association as read only" do
        expect{ Post.first.generic_record.save }.to raise_error(ActiveModel::ReadOnlyRecord)
      end
    end

    it "explodes" do
      Post.first.blah
    end

  end

end
