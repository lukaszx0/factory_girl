require 'spec_helper'
require 'acceptance/acceptance_helper'

describe "a created instance" do
  include FactoryGirl::Syntax::Methods

  before do
    define_model('User')

    define_model('Post', :user_id => :integer) do
      belongs_to :user
    end

    FactoryGirl.define do
      factory :user

      factory :post do
        user
      end
    end
  end

  subject { create('post') }

  it "saves" do
    should_not be_new_record
  end

  it "assigns and saves associations" do
    subject.user.should be_kind_of(User)
    subject.user.should_not be_new_record
  end
end

describe "a custom create" do
  include FactoryGirl::Syntax::Methods

  before do
    define_class('User') do
      def initialize
        @persisted = false
      end

      def persist
        @persisted = true
      end

      def persisted?
        @persisted
      end
    end

    FactoryGirl.define do
      factory :user do
        to_create do |user|
          user.persist
        end
      end
    end
  end

  it "uses the custom create block instead of save" do
    FactoryGirl.create(:user).should be_persisted
  end
end

describe "monkey patching" do
  include FactoryGirl::Syntax::Methods

  before do
    define_model('User', :name => :string, :is_admin => :boolean) do
      def has_name?
        not name.empty?
      end

      def admin?
        is_admin
      end
    end

    FactoryGirl.define do
      factory :user do
      end

      factory :admin, :parent => :user do
        is_admin true
      end
    end
  end

  it "allows monkey patching" do
    FactoryGirl.modify do
      factory :user do
        name "New User"
      end
    end
    FactoryGirl.create(:user).should have_name
  end

  it "inherits new attributes to child factories" do
    FactoryGirl.modify do
      factory :user do
        name "New User"
      end
    end
    FactoryGirl.create(:admin).should have_name
  end

  it "doesn't overwrite already defined child's attributes" do
    FactoryGirl.modify do
      factory :user do
        is_admin false
      end
    end
    FactoryGirl.create(:admin).should be_admin
  end

  it "raises an exception if the factory was not defined before" do
    lambda {
      FactoryGirl.modify do
        factory :unknown_factory do
        end
      end
    }.should raise_error(ArgumentError)
  end
end
