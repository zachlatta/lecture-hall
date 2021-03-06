require 'rouge/plugins/redcarpet'

# Instances of MarkdownService are *not* threadsafe. Ye be warned, here be dragons.
class MarkdownService
  class Renderer < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
    include Redcarpet::Render::SmartyPants

    def preprocess(doc)
      EmojiParser.parse(doc) do |emoji|
        img = %(<img src="/images/emoji/#{emoji.image_filename}" ) +
              %(alt=":#{emoji.name}:" class="emoji">)

        img.html_safe
      end
    end

    def link(link, title, content)
      if link.starts_with?("http")
        %(<a href="#{link}" title="#{title}" target="_blank" ) +
          %(rel="noreferrer">#{content}</a>)
      else
        %(<a href="#{link}" title="#{title}">#{content}</a>)
      end
    end

    # type can be either "url" or "email", but I doubt email links will be used
    # much if at all. So this only addresses the "url" case
    def autolink(link,type) 
      %(<a href="#{link}" target="_blank" rel="noreferrer">#{link}</a>)
    end
  end

  # This renders HTML sidebars to be used with scrollspy to track workshop
  # content. You *must* create a new SidebarRenderer for each sidebar you plan
  # to render.
  #
  # Example output:
  #
  # <nav class="workshop-sidebar hidden-print hidden-xs hidden-sm affix">
  #   <ul id="sidebar" class="nav nav-stacked fixed">
  #     <li>
  #       <a href="#part-i-setup">Part I: Setup</a>
  #       <ul class="nav nav-stacked">
  #         <li><a href="#1-signing-up-for-github">1) Signing Up for GitHub</a></li>
  #         <li><a href="#2-creating-your-first-github-repository">2) Creating Your First GitHub Repository</a></li>
  #       </ul>
  #     </li>
  #     <li>
  #       <!-- And so on -->
  #     </li>
  #   </ul>
  # </nav>
  class SidebarRenderer < Redcarpet::Render::Base
    include Redcarpet::Render::SmartyPants

    attr_accessor :outline

    def initialize(md_parser)
      @outline = []
      @md_parser = md_parser

      super()
    end

    def header(text, level)
      @outline << [level, text]
      nil
    end

    # Do the actual rendering here
    def doc_footer
      in_section = false
      section_has_children = false
      parent_level = 2
      child_level = 3

      html = %(
<nav class="workshop-sidebar hidden-print hidden-xs hidden-sm affix">
  <ul id="sidebar" class="nav nav-stacked fixed">
).lstrip

      html += @outline.inject('') do |html, data|
        level, text = data

        if !in_section and level == parent_level
          html += "    <li>\n"\
                  "      #{nav_link text}\n"
          in_section = true
        elsif in_section
          if level == child_level
            if !section_has_children
              html += %(      <ul class="nav nav-stacked">\n) +
                      %(        <li>#{nav_link text}</li>\n)
              section_has_children = true
            else
              html += "        <li>#{nav_link text}</li>\n"
            end
          elsif level == parent_level
            if section_has_children
              html += "      </ul>\n"\
                      "    </li>\n"\
                      "    <li>\n"\
                      "      #{nav_link text}\n"
              section_has_children = false
            else
              html += "    </li>\n"\
                      "    <li>\n"\
                      "      #{nav_link text}\n"
            end
          end
        end

        html
      end

      if in_section and section_has_children
        html += "      </ul>\n"
        section_has_children = false
      end

      if in_section
        html += "    </li>\n"
        in_section = false
      end

      html += "  </ul>\n"\
              "</nav>"

      html
    end

    private

    def nav_link(text)
      rendered = @md_parser.render(text).strip
      %(<a href="##{id_slug text}">#{rendered}</a>)
    end

    # Converts the given text to a slug usable as an ID in HTML.
    #
    # Example conversions:
    #
    #  "Personal Website" -> "personal-website"
    #  "1) Testing McTestFace" -> "1-testing-mctestface"
    #  "Prophet   orpheus" -> "prophet-orpheus"
    def id_slug(text)
      text
        .gsub(/[^0-9A-Za-z ]/, '') # strip special characters
        .downcase
        .split(' ')
        .join('-')
    end
  end

  def initialize
    @renderer = Renderer.new(
      with_toc_data: true
    )
    @parser = Redcarpet::Markdown.new(
      @renderer,
      autolink: true,
      tables: true,
      strikethrough: true,
      fenced_code_blocks: true,
    )

    @sidebar_renderer = SidebarRenderer.new(@parser)
    @sidebar_parser = Redcarpet::Markdown.new(@sidebar_renderer)
  end

  def render_sidebar(text)
    @sidebar_parser.render(text)
  end

  def render(text)
    @parser.render(text)
  end
end
