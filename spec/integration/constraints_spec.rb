require "spec_helper"

class Author < ActiveRecord::Base; end
class Book < ActiveRecord::Base; end

def create_book(attributes = {})
  attributes = {
    author_id: 1,
    title: "On the Origin of Species",
    state: "available",
    published_month: 1
  }.update(attributes)

  Book.create!(attributes)
end

RSpec.describe "Constraints" do
  before do
    Author.delete_all
    Author.create!(id: 1, name: "Charles Darwin")
  end

  it "raises an error if the author is not present" do
    expect { create_book(author_id: 2) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { create_book(author_id: 1) }.to_not raise_error
  end

  it "raises an error if the title is not present" do
    expect { create_book(title: "") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(title: "On the Origin of Species") }.to_not raise_error
  end

  it "raises an error if the title contains a non-ASCII letter, non-number, or non-whitespace, non-tab character" do
    expect { create_book(title: "&") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(title: "\tOn the Origin of Species") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(title: "On the Origin of Species") }.to_not raise_error
  end

  it "raises an error if the state is invalid" do
    expect { create_book(state: "burned") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(state: "available") }.to_not raise_error
  end

  it "raises an error if the due date is not present and the book is on loan" do
    expect { create_book(state: "on_loan") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(state: "on_loan", due_date: Time.now) }.to_not raise_error
  end

  it "raises an error if holder is not present and the book is on hold" do
    expect { create_book(state: "on_hold") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(state: "on_hold", holder: "Jane Citizen") }.to_not raise_error
  end

  it "raises an error if the published month is not between 1 and 12" do
    expect { create_book(published_month: 0) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(published_month: 13) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(published_month: 1) }.to_not raise_error
  end

  it "raises an error if the call number length is not between 1 and 255" do
    expect { create_book(call_number: "") }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(call_number: "K" * 256) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    expect { create_book(call_number: "KF8840 .F72 1999") }.to_not raise_error
  end
end
