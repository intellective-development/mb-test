class Admin::Merchandise::DistributorsController < Admin::BaseController
  def index
    params[:page] ||= 1
    @distributors = Distributor.name_filter(params)
                               .order('name ASC')
                               .page(pagination_page)
                               .per(pagination_rows)
  end

  def show
    @distributor = Distributor.find(params[:id])
  end

  def new
    form_info
    @distributor = Distributor.new
  end

  def create
    @distributor = Distributor.new(allowed_params)
    if @distributor.save
      flash[:notice] = 'Successfully created distributor.'
      redirect_to admin_merchandise_distributor_url(@distributor)
    else
      form_info
      render action: 'new'
    end
  end

  def edit
    form_info
    @distributor = Distributor.find(params[:id])
  end

  def update
    @distributor = Distributor.find(params[:id])
    if @distributor.update(allowed_params)
      flash[:notice] = 'Successfully updated distributor.'
      redirect_to admin_merchandise_distributor_url(@distributor)
    else
      form_info
      render action: 'edit'
    end
  end

  def destroy
    @distributor = Distributor.find(params[:id])
    @distributor.destroy
    redirect_to admin_merchandise_distributors_url
  end

  private

  def form_info
    @distributors = Distributor.order(:name).collect { |ts| [ts.name, ts.id] }
  end

  def allowed_params
    params.require(:distributor).permit(:name)
  end
end
