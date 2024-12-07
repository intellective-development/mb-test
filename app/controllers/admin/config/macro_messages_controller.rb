class Admin::Config::MacroMessagesController < Admin::Config::BaseController
  before_action :set_macro_message, only: %i[show edit update destroy content]
  skip_before_action :verify_super_admin, only: %i[content]
  before_action :verify_admin, only: %i[content]

  def index
    @macro_messages = MacroMessage.all
  end

  def show; end

  def new
    @macro_message = MacroMessage.new
  end

  def edit; end

  def create
    @macro_message = MacroMessage.new(macro_message_params)
    if @macro_message.save
      flash[:notice] = 'Successfully created a macro message'
      redirect_to admin_config_macro_message_path(@macro_message)
    else
      render action: 'new'
    end
  end

  def update
    @macro_message.assign_attributes(macro_message_params)
    if @macro_message.save
      flash[:notice] = 'Successfully updated the macro message'
      redirect_to admin_config_macro_message_path(@macro_message)
    else
      render action: 'edit'
    end
  end

  def destroy
    @macro_message.destroy
    flash[:notice] = 'Macro message deleted'
    redirect_to admin_config_macro_messages_path
  end

  def content
    render json: {
      text: @macro_message.text
    }
  end

  private

  def set_macro_message
    @macro_message = MacroMessage.find(params[:id])
  end

  def macro_message_params
    params.require(:macro_message).permit(:name, :text, :key)
  end
end
