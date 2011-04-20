require "rspec"
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Paperproposal" do

  before(:all) do
    @paperproposal = Paperproposal.find(2)
    @author = User.find(6)
    @senior = User.find(4)
    @corresponding = @author
    @paperproposal_stranger = User.find(5)
  end

  it "calc authorship" do
    @paperproposal.calc_authorship(@author).should == "Author"
    @paperproposal.calc_authorship(@senior).should == "Senior author"
    @paperproposal.calc_authorship(@corresponding).should_not == "Corresponding author"
    @paperproposal.calc_authorship(@paperproposal_stranger).should == nil
  end
end