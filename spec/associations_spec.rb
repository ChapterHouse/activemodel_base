require 'spec_helper'

class Author < ActiveModel::Base

  attribute :name, :type => :string, :id => true
  has_many :posts

  Names = ["Adam", "Bob", "Charlie", "Diane"]
  @@all = []
  
  def self.all
    if @@all.empty?
      Names.each { |name| @@all << new(:name => name) }
      @@all.each(&:save)
    end
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
    if @@all.empty?
      Descriptions.each { |description| @@all << new(:description => description) }
      @@all.each(&:save)
    end
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
    if @@all.empty?
      5.times { |x| @@all << new(:id => x, :value => x*x) }
      @@all.each(&:save)
    end
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
      @@all.each(&:save)
    end if @@all.empty?
    @@all
  end 

  def self.reset_all
    @@all = []
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

      it "provides type saftey" do
#        pending "test with AssociationTypeMismatch"
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

  end

  describe "#has_many" do

    context "with no options" do
  
      it "has a read association_ids accessor" do
        Author.first.should respond_to(:post_ids)
      end

      it "has a write association_ids accessor" do
        Author.first.should respond_to(:post_ids=)
      end

      it "has a read association accessor" do
        Author.first.should respond_to(:posts)
      end

      it "has a write association accessor" do
        Author.first.should respond_to(:posts=)
      end

      it "returns an array of associations that matches what can be found manually" do
        author = Author.first
        author.posts.should == Post.find_all_by_author_id(author.id)
      end

      it "has a array of association_ids that matches the array of ids of the retrieved associations" do
        author = Author.first
        author.post_ids.should == Post.find_all_by_author_id(author.id).map(&:id)
      end

      it "should reassign associations by array assignment" do
        author = Author.first
        second_author = Author.last
        author.posts.should_not be_empty
        second_author.posts.should_not be_empty

        assigned_posts = second_author.posts
        author.posts = assigned_posts

        second_author.posts(true).should be_empty
        Post.find_by_author_id(second_author.id).should be_nil
        author.posts.should == assigned_posts
        Post.find_all_by_author_id(author.id).should == assigned_posts
      end

      it "should reassign associations by array id assignment" do
        author = Author.first
        second_author = Author.last
        author.posts.should_not be_empty
        second_author.posts.should_not be_empty
        
        assigned_posts = second_author.posts
        assigned_post_ids = second_author.post_ids
        author.post_ids = assigned_post_ids

        second_author.posts(true).should be_empty
        Post.find_by_author_id(second_author.id).should be_nil
        author.posts.should == assigned_posts
        Post.find_all_by_author_id(author.id).should == assigned_posts
      end


      it "should clear the associations" do
        author = Author.first
        author.posts.should_not be_empty
        author.posts.clear
        author.posts.should be_empty
        Post.find_by_author_id(author.id).should be_nil
      end

      it "should delete selected associationss" do
        author = Author.first
        remaining_posts = author.posts
        posts_to_remove = []
        posts_to_remove << remaining_posts.pop
        posts_to_remove << remaining_posts.shift
        
        author.posts.delete(posts_to_remove)
        author.posts.should == remaining_posts
        Post.find_all_by_author_id(author.id).should == remaining_posts
        Post.find(posts_to_remove.map(&:id)).map(&:author_id).compact.should be_empty
      end

# 
      # it "changes the association if the association_id changes" do
        # post = Post.first
        # next_author = Author.next_author(post.author)
        # post.author_id = next_author.id
        # post.author.should equal(next_author)
      # end
# 
      # it "changes the association_id if the association changes" do
        # post = Post.first
        # next_author = Author.next_author(post.author)
        # post.author = next_author
        # post.author_id.should equal(next_author.id)
      # end
# 
      # it "allows nil to be set for the association_id" do
        # post = Post.first
        # post.author_id = nil
        # post.should be_valid
      # end
# 
      # it "allows nil to be set for the association" do
        # post = Post.first
        # post.author = nil
        # post.should be_valid
      # end
# 
      # it "changes the association to nil if the association_id changes to nil" do
        # post = Post.first
        # post.author_id = nil
        # post.author.should be_nil
      # end
# 
      # it "changes the association_id to nil if the association changes to nil" do
        # post = Post.first
        # post.author = nil
        # post.author_id.should be_nil
      # end
# 
      # it "provides type saftey" do
        # pending "test with AssociationTypeMismatch"
      # end

    end

  end

end
