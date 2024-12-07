module Dashboard
  module Integration
    module ThreeJMS
      module Builder
        class CommentBuilder
          attr_reader :comment

          def self.build
            builder = new
            yield(builder)
            builder.item
          end

          def initialize
            @comment = Dashboard::Integration::ThreeJMS::Models::Comment.new
          end

          def set_note(note)
            @comment.note = note
          end

          def set_user(user)
            @comment.user = user.to_s
          end

          def set_file(file)
            @comment.file = file
          end

          def to_s
            string = "#{@comment.user} wrote:<br /><br />"
            string += @comment.note

            if @comment.file.present?
              string += '<br /><br />'
              string += "Attachment: <a href='#{@comment.file}' target='_blank'>#{@comment.file}</a>"
            end

            string
          end
        end
      end
    end
  end
end
