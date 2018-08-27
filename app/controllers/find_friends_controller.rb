class FindFriendsController < ApplicationController

  before_action :authenticate_user!

  def index
    friends_ids = current_user.friend_ids.empty?? 'x' : current_user.friend_ids
    @users = User.where("id not in (?) AND id != ?", friends_ids, current_user).paginate(page: params[:page])
    respond_to do |format|
      format.js
      format.html
    end
  end
end
