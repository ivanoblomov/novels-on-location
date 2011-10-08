require File.dirname(__FILE__) + '/../spec_helper'

describe LocationsController do
  before :each do
    @location = Location.new :id => 1, :lat_lng => ['1', '2'], :user_id => 1
  end

  it 'gets index action' do
    Location.expects(:all).returns([@location]).at_least_once
    get :index
    assert assigns(:locations)
    response.should render_template('layouts/application')
  end

  it 'gets new action' do
    controller.stubs(:render)
    Location.expects(:new)
    get :new, @location.attributes
    asserts assigns(:location).instance_of(Location)
  end

  it 'posts create action' do
    controller.stubs(:render)
    Location.expects(:create)
    post :create, :location => {:title => nil}
  end

  it 'puts update action' do
    controller.stubs(:render)
    Location.expects(:find).returns(@location)
    @location.expects(:update_attributes)
    put :update, :id => 1, :location => {:title => nil}
  end

  it 'deletes destroy action and redirects' do
    controller.stubs(:render)
    Location.expects(:find).returns(@location)
    @location.expects(:destroy)
    delete :destroy, :id => 1
  end
end
