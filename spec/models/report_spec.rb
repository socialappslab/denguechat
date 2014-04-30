# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	it "validates status" do
		report = Report.create(:reporter_id => 1)
		expect(report.errors.full_messages).to include("Status é obrigatório")
	end

	it "validates reporter" do
		report = Report.create(:status => :reported)
		expect(report.errors.full_messages).to include("Reporter é obrigatório")
	end

	it "does not require presence of location" do
		r = FactoryGirl.build(:report)
		expect { r.save }.to change(Report, :count).by(1)
	end

  describe "fetching" do
		let(:user) { FactoryGirl.create(:user) }
  	before(:each) do

      eliminated_attributes = {:elimination_method => "Method",
                               :status => Report::STATUS[:eliminated],
                               :eliminator => user,
                               :after_photo => Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')}

  		@identified1 = FactoryGirl.create(:report)
  		@identified2 = FactoryGirl.create(:report)
  		@identified3 = FactoryGirl.create(:report)

  		@eliminated1 = FactoryGirl.create(:report, eliminated_attributes)
      @eliminated2 = FactoryGirl.create(:report, eliminated_attributes)
      @eliminated3 = FactoryGirl.create(:report, eliminated_attributes)

    end
		
  	context "identified reports" do
			it "returns identified results" do
				Report.identified_reports.should ==  [@identified1, @identified2, @identified3]
			end
		end

		context "eliminated_reports" do
			it "returns eliminated results" do
				Report.eliminated_reports.should == [@eliminated1, @eliminated2, @eliminated3]
			end
		end
  end
end
