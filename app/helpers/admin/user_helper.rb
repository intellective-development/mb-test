module Admin::UserHelper
  def format_loyalty_points(loyalty_point_balance)
    table = '<table><tr>'
    loyalty_point_balance.each { |k, _v| table += "<th>#{k}</th>" }
    table += '</tr><tr>'
    loyalty_point_balance.each { |_k, v| table += "<th>#{v}</th>" }
    table += '</tr></table>'
  end
end
