# encoding: utf-8

require 'spec_helper'
describe "Users", :type => :feature do
  context "when editing one's information" do
    let(:house) { FactoryGirl.create(:house) }
    let!(:user) { FactoryGirl.create(:user, :phone_number => nil, :carrier => nil, :house_id => house.id, :prepaid => nil, :neighborhood_id => nil) }

    before(:each) do
      sign_in(user)
      visit edit_user_path(user)
    end

    context "when the form encounters an error" do
      # it "keeps house name" do
      #   fill_in :user_house_attributes_name, :with => "Test house"
      #
      #   within ".edit_house" do
      #     click_button "Confirmar"
      #   end
      #
      #   expect(page).to have_content("Informe a sua operadora")
      #   find_field("user_house_attributes_name").value.should eq "Test house"
      # end

      it "keeps cellphone info" do
        # check "cellphone"
        # This is a hack that bypasses the need to have a JS driver.
        fill_in :user_phone_number, :with => "000000000000"
        fill_in :user_carrier, :with => "xxx"

        # within ".edit_house" do
        click_button "Confirmar"
        # end

        find_field("user_carrier").value.should eq "xxx"
        find_field("user_phone_number").value.should eq "000000000000"
      end

      it "keeps gender information" do
        choose "user_gender_false"

        # within ".edit_house" do
        click_button "Confirmar"
        # end

        expect(page).to have_css("#user_gender_false[checked='checked']")
      end

      it "keeps first name information" do
        fill_in :user_first_name, :with => "I AM TESTER"
        # within "#name_edit_box" do
        click_button "Confirmar"
        # end
        expect(find_field("user_first_name").value).to eq("I AM TESTER")
      end


      it "keeps last name information" do
        fill_in :user_last_name, :with => "I AM TESTER"
        # within "#name_edit_box" do
        click_button "Confirmar"
        # end
        expect(find_field("user_last_name").value).to eq("I AM TESTER")
      end

      it "keeps nickname information" do
        fill_in :user_nickname, :with => "I AM TESTER"
        # within "#name_edit_box" do
        click_button "Confirmar"
        # end
        expect(find_field("user_nickname").value).to eq("I AM TESTER")
      end

      it "keeps nickname information" do
        selected_name = user.display_name_options[1]
        expect(find_field("user_display").value).not_to eq(selected_name[1])

        select selected_name[0], :from => "user_display"
        # within "#name_edit_box" do
        click_button "Confirmar"
        # end
        expect(find_field("user_display").value).to eq(selected_name[1])
      end
    end
  end

  #---------------------------------------------------------------------------

end
