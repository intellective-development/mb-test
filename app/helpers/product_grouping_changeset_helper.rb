module ProductGroupingChangesetHelper
  def format_changes(change)
    case change[0]
    when '~'
      current_key = change[1]
      "#{content_tag(:span, "→ #{change[1]}:", class: 'changeset_key')} #{content_tag(:span, (change[2]).to_s, class: 'changeset_edit_original_value')} #{content_tag(:span, (change[3]).to_s, class: 'changeset_add_value')}"
    when '+'
      "#{content_tag(:span, "+ #{change[1]}:", class: 'changeset_key')} #{content_tag(:span, (change[2]).to_s, class: 'changeset_add_value')}"
    when '-'
      content_tag(:span, (change[2]).to_s, class: 'changeset_delete')
    end
  end
end
