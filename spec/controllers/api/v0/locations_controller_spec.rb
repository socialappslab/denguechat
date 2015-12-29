# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::LocationsController do
  render_views

  it "responds with correct locations" do
    5.times do |index|
      create(:location, :address => "N0#{index}002", :neighborhood_id => 1)
    end

    get "index", :addresses => Location.pluck(:address).join(","), :format => :json
    expect( JSON.parse(response.body)["locations"].map {|loc| loc["id"]} ).to eq(Location.order("address ASC").pluck(:id))
  end

  it "responds with an error if location is missing" do
    get "index", :addresses => "TEST", :format => :json
    expect( JSON.parse(response.body)["message"] ).to eq("No pudo encontrar lugar con la dirección TEST")
  end

  #--------------------------------------------------------------------------

  describe "Updating a location" do
    let(:location)      { create(:location) }

    it "updates location address" do
      put :update, :id => location.id, :location => { :address => "Haha", :neighborhood_id => 100 }
      expect(location.reload.address).to eq("Haha")
      expect(location.reload.neighborhood_id).to eq(100)
    end
  end
end
