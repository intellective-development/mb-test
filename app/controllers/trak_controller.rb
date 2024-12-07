class TrakController < ApplicationController
  skip_before_action
  protect_from_forgery except: %i[started arriving completed failed validate]

  # Task has been started by the worker. This should be taken as an order confirmation.
  def started
    Rails.logger.info("WEBHOOK: #{task_params[:taskId]} Starting")

    Shipment.find_by(trak_id: task_params[:taskId])&.start_delivery!

    render nothing: true
  end

  # Worker is ~150m from destination. This should be used to trigger any customer facing
  # push notifications etc.
  def arriving
    Rails.logger.info("WEBHOOK: #{task_params[:taskId]} Arriving")
    render nothing: true
  end

  # Task has been completed. This should be used to indicate that an order has been
  # delivered.
  def completed
    Rails.logger.info("WEBHOOK: #{task_params[:taskId]} Completed")

    Shipment.find_by(trak_id: task_params[:taskId])&.deliver!

    render nothing: true
  end

  # Task has failed or been cancelled. This should be piped to customer service and logged.
  def failed
    Rails.logger.info("WEBHOOK: #{task_params[:taskId]} Completed")
    render nothing: true
  end

  # Used during initial setup
  def validate
    Rails.logger.info("WEBHOOK: Validated Endpoint - #{request.url}")
    render text: validate_params[:check]
  end

  private

  def task_params
    params.permit(:time, :taskId)
  end

  def validate_params
    params.permit(:check)
  end
end
