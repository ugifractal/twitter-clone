class HomeController < ApplicationController
  before_action :authenticate_user!
  def index
    @tweets = Tweet.where("user_id in (?) OR user_id = ?", current_user.friend_ids, current_user).paginate(page: params[:page]).order('created_at DESC')
  end

  def get_image
    begin
      page = MetaInspector.new(params[:url])
      render :json => {'status' => 'ok', 'image' => page.images.best}.to_json
    rescue Exception => e
      render :json => {'status' => 'error'}.to_json
    end
  end
end
