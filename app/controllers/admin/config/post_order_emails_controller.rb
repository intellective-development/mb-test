class Admin::Config::PostOrderEmailsController < Admin::Config::BaseController
  def index
    @emails = PostOrderEmail.all
  end

  def show
    @email = PostOrderEmail.find(params[:id])
  end

  def new
    @email = PostOrderEmail.new
  end

  def edit
    @email = PostOrderEmail.find(params[:id])
  end

  def create
    @email = PostOrderEmail.new(allowed_params)

    if @email.save
      redirect_to(admin_config_post_order_emails_url, notice: 'Email was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    @email = PostOrderEmail.find(params[:id])

    if @email.update(allowed_params)
      redirect_to(admin_config_post_order_emails_url, notice: 'Email was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:post_order_email).permit(:active, :tag_name, :template_slug, :subject)
  end
end
