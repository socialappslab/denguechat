# encoding: utf-8
require 'spec_helper'

describe UsersController do
	render_views

	describe "Registering" do
		context "when user inputs valid information" do
			it "redirects them to their edit page" do
				visit root_path

				fill_in "user_email", 		 					 :with => "test@denguetorpedo.com"
				fill_in "user_first_name", 					 :with => "Test"
				fill_in "user_last_name",  					 :with => "Tester"
				fill_in "user_password", 						 :with => "abcdefg"
				fill_in "user_password_confirmation", :with => "abcdefg"
				click_button "Cadastre-se!"

				user = User.find_by_email("test@denguetorpedo.com")
				expect(current_path).to eq( edit_user_path(user) )
			end
		end
	end

	describe "Updating" do
		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in(user)
		end

		context "when user inputs invalid information" do
			it "notifies the user of short phone number" do
				visit edit_user_path(user)
				fill_in "user_phone_number", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Número de celular invalido.  O formato correto é 0219xxxxxxxx")
			end

			it "notifies the user of missing carrier" do
				visit edit_user_path(user)
				fill_in "user_carrier", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Informe a sua operadora")
			end

			it "notifies the user of missing house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Preencha o nome da casa")
			end

			it "notifies the user of a short house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => "A"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Insira um nome da casa válido")
			end

			it "notifies the user of missing house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				save_and_open_page
				expect(page).to have_content("Preencha o nome da casa.")
			end

			it "notifies the user of a short house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => "A"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Insira um nome da casa válido.")
			end
		end

		#----------------------------------------------------------------------------

		context "when user inputs valid information" do
			it "updates the user's neighborhood" do
				# TODO: Pending until we introduce a second neighborhood
				pending

				expect(user.neighborhood_id).to eq(Neighborhood.first.id)

				visit edit_user_path(user)

				select Neighborhood.all[1].id, :from =>  "user_neighborhood_id"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.neighborhood_id).to eq(Neighborhood.all[1].id)
			end

			it "updates the user's house" do
				visit edit_user_path(user)

				fill_in "user_house_attributes_name", :with => "TEST"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.name).to eq("TEST")
			end

			it "sets the user's house neighborhood" do
				user.house.neighborhood_id = nil
				user.house.save(:validate => false)

				visit edit_user_path(user)
				select Neighborhood.first.name, :from => "user_neighborhood_id"

				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.neighborhood.id).to eq(Neighborhood.first.id)
			end

			it "updates the user's house location" do
				user.house.location_id = nil
				user.house.save(:validate => false)

				visit edit_user_path(user)
				fill_in "user_location_street_type", 	:with => "Rua"
				fill_in "user_location_street_name", 	:with => "Boca"
				fill_in "user_location_street_number", :with => "50"

				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.location.street_type).to eq("Rua")
			end

			it "updates the user's house location" do
				visit edit_user_path(user)
				fill_in "user_location_street_type", 	:with => "Rua"
				fill_in "user_location_street_name", 	:with => "Boca"
				fill_in "user_location_street_number", :with => "50"

				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.location.street_type).to eq("Rua")
			end
		end

	end

	#
	# def valid_attributes
	# end
	#
	# def sponsor_attributes
	# 	{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "lojista", phone_number: "15105421895", house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	# end
	#
	# def verifier_attributes
	# 	{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "verificador", phone_number: "15105421895", house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	# end
	#
	# def visitor_attributes
	# 	{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "verificador", phone_number: "0219xxxxxxxx", :carrier => "Test Carrier", :prepaid => true, house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	#
	# end
	#

	# before(:each) do
	# 	controller.stub(:require_login).and_return(true)
	# 	@admin = FactoryGirl.create(:admin)
	# 	@user = FactoryGirl.create(:user)
	# end
	#
	# describe "Get INDEX" do
	# 	context "when logged in with admin account" do
	# 		it "response should be success" do
	# 			controller.stub(:current_user).and_return(@admin)
	# 			get :index
	# 			response.should be_success
	# 		end
	# 	end
	#
	# 	context "when logged in with resident account" do
	# 		it "rseponse should not be success" do
	# 			controller.stub(:current_user).and_return(@user)
	# 			get :index
	# 			response.should_not be_success
	# 		end
	# 	end
	# end
	#
	#
	# describe "Get EDIT" do
	# 	context "when logged in with admin account" do
	# 		it "renders successfully" do
	# 			controller.stub(:current_user).and_return(@admin)
	# 			get :edit, id: @user.id
	# 			response.should be_success
	# 		end
	# 	end
	# end
	#
	# describe "Editing a user" do
	# 	render_views
	#
	# 	let(:user) { FactoryGirl.create(:user) }
	#
	# 	before(:each) do
	# 		cookies[:auth_token] = user.auth_token
	# 	end
	#
	#
	# 	it "asks user for a neighborhood" do
	# 		expect(user.neighborhood).to eq(nil)
	#
	# 		attrs = visitor_attributes[:user].merge(:neighborhood_id => Neighborhood.first.id)
	# 		put :update, :id => user.id, :user => attrs
	# 		expect(user.reload.neighborhood.id).to eq(Neighborhood.first.id)
	# 	end
	# end
	#
	# describe "Get Special_new" do
	# 	context "when logged in with admin account" do
	# 		before(:each) do
	# 			@admin = FactoryGirl.create(:admin)
	# 			controller.stub(:current_user).and_return(@admin)
	# 		end
	# 		it "should return success" do
	# 			get :special_new
	# 			response.should
	# 		end
	# 	end
	#
	# 	context "when looged in with other accounts type" do
	# 		before(:each) do
	# 			@user = FactoryGirl.create(:user)
	# 			controller.stub(:current_user).and_return(@user)
	# 		end
	#
	# 		it "should return failure" do
	# 			get :special_new
	# 			response.should_not be_success
	# 		end
	# 	end
	# end
	#
	# describe "Post Special_create" do
	# 	describe "when logged in with admin account" do
	# 		before(:each) do
	# 			@admin = FactoryGirl.create(:admin)
	# 			controller.stub(:current_user).and_return(@admin)
	# 		end
	# 		it "should create a sponsor successfully" do
	# 			post :special_create, sponsor_attributes
	# 			response.should be_redirect
	# 		end
	#
	# 		it "should create a verifier successfully" do
	# 			post :special_create, verifier_attributes
	# 			response.should be_redirect
	# 		end
	#
	# 		it "should create a visitor successfully" do
	# 			post :special_create, visitor_attributes
	# 			response.should be_redirect
	# 		end
	# 	end
	#
	# 	describe "when logged in with other accounts" do
	# 		before(:each) do
	# 			@user = FactoryGirl.create(:user)
	# 			controller.stub(:current_user).and_return(@user)
	# 		end
	# 		it "should not create a sponsor" do
	# 			post :special_create, FactoryGirl.attributes_for(:sponsor)
	# 			response.should_not be_success
	# 		end
	#
	# 		it "should not create a verifier" do
	# 			post :special_create, FactoryGirl.attributes_for(:verifier)
	# 			response.should_not be_success
	# 		end
	#
	# 		it "should not create a visitor" do
	# 			post :special_create, FactoryGirl.attributes_for(:visitor)
	# 			response.should_not be_success
	# 		end
	# 	end
	# end

end
