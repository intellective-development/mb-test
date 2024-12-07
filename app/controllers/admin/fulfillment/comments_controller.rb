class Admin::Fulfillment::CommentsController < Admin::Fulfillment::BaseController
  before_action :set_commentable
  before_action :set_comment, only: %i[edit update]

  def show
    @comment = @commentable.comments.find(params[:id])
    respond_to do |format|
      format.json { render json: @comment.to_json }
      format.html { render action: 'show' }
    end
  end

  def new
    @comment = @commentable.comments.new
  end

  def create
    params = allowed_params.merge!(created_by: current_user.id, user_id: @order.user_id)
    @comment = @commentable.comments.new(params)

    respond_to do |format|
      if @comment.save
        dispatch_comment_integrations
        flash[:notice] = 'Successfully created comment.'
        format.json { render json: @comment.to_json }
        format.html { redirect_to edit_admin_fulfillment_order_path(@order.number) }
      else
        format.json { render json: @comment.errors.to_json }
        format.html { render action: 'new' }
      end
    end
  end

  def edit
    case @comment.commentable.class.name
    when Shipment.name
      @shipment = @comment.commentable
      @order = @shipment.order
    when Order.name
      @order = @comment.commentable
    end
  end

  def update
    if @comment.updateble?
      @comment.update!(allowed_params)
      redirect_to edit_admin_fulfillment_order_path(@order.number)
    else
      flash[:alert] = "This comment can't be updated"
      redirect_to :edit, id: @comment.id
    end
  end

  private

  def dispatch_comment_integrations
    if @shipment
      effective_supplier = @shipment.effective_supplier
      Dashboard::Integration::ThreeJMSDashboard.new(effective_supplier).send_comment(@shipment, @comment) if effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS
    end
  end

  def allowed_params
    params.require(:comment).permit(:note, :file)
  end

  def set_commentable
    if params[:shipment_id]
      @shipment = Shipment.find(params[:shipment_id])
      @order = @shipment.order
      @commentable = @shipment
    elsif params[:order_id]
      @order = Order.find(params[:order_id])
      @commentable = @order
    end
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
