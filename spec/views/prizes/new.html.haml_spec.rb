require 'spec_helper'

describe "prizes/new" do
  before(:each) do
    @user = FactoryGirl.create(:user)
    assign(:prize, stub_model(Prize,
      :prize_name => "MyString",
      :cost => 1,
      :stock => 1,
      :user_id => @user.id,
      :description => "MyText",
      :redemption_directions => "MyText"
    ).as_new_record)
  end

  it "renders new prize form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => prizes_path, :method => "post" do
      assert_select "input#prize_prize_name", :name => "prize[prize_name]"
      assert_select "input#prize_cost", :name => "prize[cost]"
      assert_select "input#prize_stock", :name => "prize[stock]"
      assert_select "input#prize_user_id", :name => "prize[user_id]"
      assert_select "textarea#prize_description", :name => "prize[description]"
      assert_select "textarea#prize_redemption_directions", :name => "prize[redemption_directions]"
    end
  end
end
