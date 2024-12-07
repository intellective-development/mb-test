class FormNotifier < BaseNotifier
  KEY_BLACKLIST = %w[utf8 authenticity_token type commit controller action].freeze
  OPS_TYPES = %w[inventory reports invoice].freeze

  def supplier_update(params)
    @params = params

    subject = format_subject((params[:subject]).to_s)
    to = if OPS_TYPES.include?(params[:type])
           'ops@minibardelivery.com'
         else
           'help@minibardelivery.com'
         end
    from = 'Minibar Squirrel <squirrel@minibardelivery.com>'

    mail(to: to, from: from, subject: subject) do |format|
      format.html { render layout: 'email_ink' }
    end
  end
end
