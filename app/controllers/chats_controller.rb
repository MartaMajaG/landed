class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Load all chats for the current user, most recent first
    @chats = current_user.chats.order(created_at: :desc)
  end

  def show
    # Find a specific chat belonging to the current user
    @chat = current_user.chats.find(params[:id])
  end

  def new
    # Initialize a new chat instance for the upload form
    @chat = Chat.new
  end

  def create
    # Build a chat instance associated with the current user
    @chat = current_user.chats.build(chat_params)

    if @chat.save
      # Redirect to the show page with a success message
      redirect_to chat_path(@chat), notice: "PDF uploaded successfully. Processing started."
    else
      # Re-render the form if validations fail
      render :new, status: :unprocessable_entity
    end
  end

  private

  def chat_params
    # Strong parameters permitting the checklist item ID and the attached PDF
    params.require(:chat).permit(:checklist_item_id, :pdf)
  end
end
