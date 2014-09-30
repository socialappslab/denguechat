# encoding: UTF-8

class ConversationsController < ApplicationController
  before_filter :require_login
  before_filter :clear_new_notifications, :only => [:index]

  def index
    @conversations  = @current_user.conversations.order("updated_at DESC")
    @conversation   = Conversation.new
    @message        = Message.new
  end

  def show
    @conversation = @current_user.conversations.find_by_id(params[:id])
    @messages     = @conversation.messages.order("created_at ASC")
    @message      = Message.new
  end

  private

  def clear_new_notifications
    @message_notifications.each do |mn|
      mn.update_column(:viewed, true)
    end

    # Now, set message_notifications to [] to not display 0 in
    # nagging-badge.
    @message_notifications = []
  end
end