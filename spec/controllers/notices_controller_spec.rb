require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe NoticesController do

  # This should return the minimal set of attributes required to create a valid
  # Notice. As you add validations to Notice, be sure to
  # adjust the attributes here as well.
  before(:each) do
    @neighborhood = FactoryGirl.create(:neighborhood)
  end

  let(:valid_attributes) { { title: "Hihi", description: "Description", summary: "Summary", neighborhood_id: @neighborhood.id, institution_name: "DT Headquarter"} }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # NoticesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all notices as @notices" do
      notice = Notice.create! valid_attributes
      get :index, {}, valid_session
      assigns(:notices).should eq([notice])
    end
  end

  describe "GET show" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :show, {:id => notice.to_param}, valid_session
      assigns(:notice).should eq(notice)
    end
  end

  describe "GET new" do
    it "assigns a new notice as @notice" do
      get :new, {}, valid_session
      assigns(:notice).should be_a_new(Notice)
    end
  end

  describe "GET edit" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :edit, {:id => notice.to_param}, valid_session
      assigns(:notice).should eq(notice)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Notice" do
        expect {
          post :create, {:notice => valid_attributes}, valid_session
        }.to change(Notice, :count).by(1)
      end

      it "assigns a newly created notice as @notice" do
        post :create, {:notice => valid_attributes}, valid_session
        assigns(:notice).should be_a(Notice)
        assigns(:notice).should be_persisted
      end

      it "redirects to the created notice" do
        post :create, {:notice => valid_attributes}, valid_session
        response.should redirect_to(Notice.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved notice as @notice" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        assigns(:notice).should be_a_new(Notice)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested notice" do
        notice = Notice.create! valid_attributes
        # Assuming there are no other notices in the database, this
        # specifies that the Notice created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Notice.any_instance.should_receive(:update_attributes).with({ "title" => "MyString" })
        put :update, {:id => notice.to_param, :notice => { "title" => "MyString" }}, valid_session
      end

      it "assigns the requested notice as @notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        assigns(:notice).should eq(notice)
      end

      it "redirects to the notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        response.should redirect_to(notice)
      end
    end

    describe "with invalid params" do
      it "assigns the notice as @notice" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        assigns(:notice).should eq(notice)
      end

      it "re-renders the 'edit' template" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested notice" do
      notice = Notice.create! valid_attributes
      expect {
        delete :destroy, {:id => notice.to_param}, valid_session
      }.to change(Notice, :count).by(-1)
    end

    it "redirects to the notices list" do
      notice = Notice.create! valid_attributes
      delete :destroy, {:id => notice.to_param}, valid_session
      response.should redirect_to(root_url)
    end
  end

end
