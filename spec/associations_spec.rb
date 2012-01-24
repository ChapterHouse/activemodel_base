require 'spec_helper'

class Author < ActiveModel::Base

  attribute :name, :type => :string, :id => true
  has_many :posts
  has_many :documents, :class_name => "Post", :foreign_key => :writer_id


  Names = ["Adam", "Bob", "Charlie", "Diane"]
  @@all = []
  
  class << self

    def all
      populate_store if @@all.empty?
      @@all
    end 

    def next_author(author)
      find(Names[Names.index(author.id) + 1])
    end
  
    def reset_all
      @@all = []
    end

    def save(record)
      @@all << record if record.new_record?
      true
    end
  
    def populate_store
      Names.each { |name| create(:name => name) }
    end

  end

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
  end

end

class Rating < ActiveModel::Base

  attribute :description, :type => :string, :id => true

  Descriptions = ["Excellant", "Great", "Good", "Bad", "BurnIt"]

  @@all = []

  class << self

    def all
      populate_store if @@all.empty?
      @@all
    end 

    def reset_all
      @@all = []
    end

    def save(record)
      @@all << record if record.new_record?
      true
    end
  
    def populate_store
      Descriptions.each { |description| create(:description => description) }
    end

  end

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
  end

end

class GenericRecord < ActiveModel::Base
  
  attribute :value, :type => :integer
  attribute :id, :type => :integer
  
  @@all = []

  class << self

    def all
      populate_store if @@all.empty?
      @@all
    end 

    def reset_all
      @@all = []
    end

    def save(record)
      @@all << record if record.new_record?
      true
    end
  
    def populate_store
      5.times { |x| create(:id => x, :value => x*x) }
    end

  end

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
  end

end

class Post < ActiveModel::Base

  attribute :title, :type => :string, :id => true
  belongs_to :author
  belongs_to :writer, :class_name => "Author"
  belongs_to :rating, :foreign_key => :appreciation_id
  belongs_to :generic_record, :readonly => true 

  @@all = []

  class << self

    def all
      populate_store if @@all.empty?
      @@all
    end 

    def reset_all
      @@all = []
    end

    def save(record)
      @@all << record if record.new_record?
      true
    end
  
    def populate_store
      writers = Author.all.reverse
      Author.all.each do |author|
        writer = writers.shift
        3.times do |x|
          create(:title => "#{author.name}'s post number #{x}", :author_id => author.id, :writer_id => writer.id, :generic_record_id => x)
        end
      end
    end

  end

  def to_s
    "#{id} [\n" + model_attributes.keys.map { |x| "  #{x} => #{self.send(x).inspect}" }.join("\n") + "\n]"
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
        pending "test with AssociationTypeMismatch"
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

    context "with the primary key option" do
      it "should use a different primary key" do
        pending "test for effects of primary key option"
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

      it "should maintain its own proxy instance variable" do
        author = Author.first
        # Check values first and also cause the proxies to be loaded.
        author.posts.should_not equal(author.documents)
        # Now make sure the internal instance variables holding the proxies exist and are not referencing the same proxy.
        author.instance_variables.include?(:@posts_proxy).should be_true
        author.instance_variables.include?(:@documents_proxy).should be_true
        author.instance_variable_get(:@posts_proxy).should_not equal(author.instance_variable_get(:@documents_proxy))
        # In the above data, the arrays should be different too. (Yes, I had a situation where the above passed yet there was still a bug :)
        author.posts.should_not == author.documents
      end

      it "should clear the associations" do
        author = Author.first
        author.posts.should_not be_empty
        author.posts.clear
        author.posts.should be_empty
        Post.find_by_author_id(author.id).should be_nil
      end

      context "during array assignment" do

        it "should set the destination's new associations to be only the source's old assocations" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
  
          assigned_posts = source_author.posts
          destination_author.posts = assigned_posts
  
          destination_author.posts.should == assigned_posts
        end
  
        it "should save the destination's new associations to be only the source's old assocations" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
  
          assigned_posts = source_author.posts
          destination_author.posts = assigned_posts
  
          Post.find_all_by_author_id(destination_author.id).should == assigned_posts
        end
  
        it "should set the sources's associations to be empty" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
  
          assigned_posts = source_author.posts
          destination_author.posts = assigned_posts
  
          source_author.posts(true).should be_empty
        end
  
        it "should save the sources's associations as empty" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
  
          assigned_posts = source_author.posts
          destination_author.posts = assigned_posts
  
          Post.find_by_author_id(source_author.id).should be_nil
        end

      end

      context "during array id assignment" do
  
        it "should set the destination's new associations to be only the source's old assocations" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
          
          assigned_posts = source_author.posts
          assigned_post_ids = source_author.post_ids
          destination_author.post_ids = assigned_post_ids
  
          destination_author.posts.should == assigned_posts
        end
  
        it "should save the destination's new associations to be only the source's old assocations" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
          
          assigned_posts = source_author.posts
          assigned_post_ids = source_author.post_ids
          destination_author.post_ids = assigned_post_ids
  
          Post.find_all_by_author_id(destination_author.id).should == assigned_posts
        end
  
        it "should set the sources's associations to be empty" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
          
          assigned_posts = source_author.posts
          assigned_post_ids = source_author.post_ids
          destination_author.post_ids = assigned_post_ids
  
          source_author.posts(true).should be_empty
        end
  
        it "should save the sources's associations as empty" do
          destination_author = Author.first
          source_author = Author.last
          destination_author.posts.should_not be_empty
          source_author.posts.should_not be_empty
          
          assigned_posts = source_author.posts
          assigned_post_ids = source_author.post_ids
          destination_author.post_ids = assigned_post_ids
  
          Post.find_by_author_id(source_author.id).should be_nil
        end

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

      it "supports find by attributes" do
        Author.first.posts.find_by_generic_record_id(1).should == Post.find_by_generic_record_id(1)
      end

      it "allows building a new asoociation from the array" do
        author = Author.first
        title = "Build test"
        writer = Author.last
        rating = Rating.first
        generic_record = GenericRecord.last
        
        post_count = author.posts.size

        post = author.posts.build(:title => title, :writer => writer, :rating => rating, :generic_record => generic_record)

        post.should equal(author.posts.last)
        post.author.should equal(author)
        post.title.should equal(title)
        post.writer.should equal(writer)
        post.rating.should equal(rating)
        post.generic_record.should equal(generic_record)
        author.posts.size.should equal(post_count + 1)

        post.new_record?.should be_true
        Post.find_by_id(post.id).should be_nil
      end

      it "allows creating a new asoociation from the array" do
        author = Author.first
        title = "Build test"
        writer = Author.last
        rating = Rating.first
        generic_record = GenericRecord.last
        
        post_count = author.posts.size

        post = author.posts.create(:title => title, :writer => writer, :rating => rating, :generic_record => generic_record)
        
        post.should equal(author.posts.last)
        post.author.should equal(author)
        post.title.should equal(title)
        post.writer.should equal(writer)
        post.rating.should equal(rating)
        post.generic_record.should equal(generic_record)
        author.posts.size.should equal(post_count + 1)

        post.new_record?.should be_false
        Post.find_by_id(post.id).should == post
      end

    end

    context "with the class_name option" do
      it "has a normal read association_ids accessor" do
        Author.first.should respond_to(:document_ids)
      end

      it "has a normal write association_ids accessor" do
        Author.first.should respond_to(:documents=)
      end

      it "has a normal read associations accessor" do
        Author.first.should respond_to(:documents)
      end

      it "has a normal write associations accessor" do
        Author.first.should respond_to(:documents=)
      end

      it "retrieves the requested class" do
        Author.first.documents.first.should be_an_instance_of(Post)
      end
    end

    context "with the foreign_key option" do
      it "should track back to the writer through the foreign key" do
        writer = Author.first
        writers = writer.documents.map(&:writer).uniq
        writers.size.should == 1
        writers.first.should equal(writer)
      end

      it "should not track back to the writer through the default key" do
        writer = Author.first
        authors = writer.documents.map(&:author).uniq
        authors.size.should == 1
        authors.first.should_not equal(writer)
      end
    end

    context "with the primary key option" do
      it "should use a different primary key" do
        pending "test for effects of primary key option"
      end
    end

    context "with the limit option" do
      it "should use the limit for retrieval" do
        pending "test for effects of primary key option"
      end
    end

    context "with the offset option" do
      it "should use the offset for retrieval" do
        pending "test for effects of offset option"
      end
    end

    context "with the readonly option" do
      it "should set the readonly flag" do
        pending "test for effects of readonly option"
      end
    end

    context "with the validate option" do
      it "should validate at the appropriate time" do
        pending "test for effects of validate option"
      end
    end

  end


end
