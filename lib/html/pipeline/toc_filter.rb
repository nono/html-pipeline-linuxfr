module HTML
  class Pipeline

    # HTML filter that adds a 'name' attribute to all headers
    # in a document, so they can be accessed from a table of contents
    #
    # Context options:
    #   :toc_minimal_length (required) - Only add the table of contents to text with this number of characters
    #   :toc_header (required) - Introduce the table of contents with this header
    #
    class TableOfContentsFilter < Filter

      def call
        headers = Hash.new 0
        was = 2
        toc = ""
        doc.css('h1, h2, h3, h4, h5, h6').each do |node|
          level = node.name.scan(/\d/).first.to_i
          name = node.text.downcase
          name.gsub!(/[^\w\- ]/, '') # remove punctuation
          name.gsub!(' ', '-') # replace spaces with dash
          name = EscapeUtils.escape_uri(name) # escape extended UTF-8 chars

          uniq = (headers[name] > 0) ? "-#{headers[name]}" : ''
          headers[name] += 1
          node['id'] = "#{name}#{uniq}"
          while was > level
            toc << "</ul>\n</li>\n"
            was -= 1
          end
          while was < level
            toc << "<li>\n<ul>"
            was += 1
          end
          toc << "<li><a href=\"##{name}#{uniq}\">#{node.inner_html}</a></li>"
        end

        length = 0
        doc.traverse {|node| length += node.text.length if node.text? }
        return doc unless length >= context[:toc_minimal_length]

        while was > 1
          toc << "</ul>\n</li>\n"
          was -= 1
        end

        unless headers.empty?
          first_child = doc.child
          first_child.add_previous_sibling context[:toc_header]
          first_child.add_previous_sibling "<ul class=\"toc\">#{toc}</ul>"
        end
        doc
      end

      def validate
        needs :toc_minimal_length, :toc_header
      end
    end

  end
end
