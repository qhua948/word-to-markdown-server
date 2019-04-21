# frozen_string_literal: true

require 'word-to-markdown'
require 'sinatra'
require 'html/pipeline'
require 'tempfile'
require 'sprockets'
require 'uglifier'
require 'sass'
require 'bootstrap'
require 'autoprefixer-rails'

module WordToMarkdownServer
  class App < Sinatra::Base
    helpers do
      def html_escape(text)
        Rack::Utils.escape_html(text)
      end

      def title
        "Word to Markdown Converter"
      end

      def description
        "Convert Word or Google documents to Markdown online"
      end

      def url
        "https://word-to-markdown.herokuapp.com"
      end
    end

    configure do
      set :server, :puma unless development?
      set :environment, Sprockets::Environment.new
      environment.append_path "assets/stylesheets"
      environment.append_path "assets/javascripts"
      environment.js_compressor  = :uglify
      environment.css_compressor = :scss
      AutoprefixerRails.install(environment)
    end

    get '/' do
      render_template :index, error: nil
    end

    post '/' do
      unless /docx?$/i.match?(params['doc'][:filename])
        error = 'It looks like you tried to upload something other than a Word Document.'
        render_template :index, error: error
      end
      md = CGI.escapeHTML(WordToMarkdown.new(params['doc'][:tempfile]).to_s)
      html = HTML::Pipeline::MarkdownFilter.new(md).call
      render_template :display, md: md, html: html, filename: params['doc'][:filename].sub(/\.docx?$/, '')
    end

    post '/raw' do
      file = Tempfile.new('word-to-markdown')
      File.write file.path, request.env['rack.request.form_vars']
      markdown = WordToMarkdown.new(file.path).to_s
      file.unlink
      markdown
    end

    get "/assets/*" do
      env["PATH_INFO"].sub!("/assets", "")
      settings.environment.call(env)
    end

    private

    def render_template(template, locals = {})
      halt erb template, layout: :layout, locals: locals
    end
  end
end
