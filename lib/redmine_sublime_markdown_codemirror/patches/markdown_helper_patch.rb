module RedmineSublimeMarkdownCodeMirror
  module Patches
    module MarkdownHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :wikitoolbar_for, :codemirror          
        end
      end


      module InstanceMethods
        def wikitoolbar_for_with_codemirror(field_id)
          @heads_for_codemirror_included = true

          url = "#{Redmine::Utils.relative_url_root}/help/#{current_language.to_s.downcase}/wiki_syntax_markdown.html"

          # wikitoolbar_for_without_codemirror(field_id) +
          javascript_tag(%(
			$(function() {
            CodeMirror.defineMode("macro", function(config, parserConfig) {
              var macroOverlay = {
                token: function(stream, state) {
                  var ch;
                  if (stream.match("{{")) {
                    while ((ch = stream.next()) != null)
                      if (ch == "}" && stream.next() == "}") {
                        stream.eat("}");
                        return "keyword";
                      }
                  } else if (stream.match("TODO")) {
                    return "todo";
                  }
                  while (stream.next() != null && !stream.match("{{", false) && !stream.match("TODO", false)) {}
                  return null;
                }
              };
              return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "text/x-markdown"), macroOverlay);
            });

            var area = document.getElementById("#{field_id}");
            var editor = CodeMirror.fromTextArea(area, {
                lineNumbers: true,
                mode: "macro",
                lineWrapping: true,
		gutters: ["CodeMirror-linenumbers"],
                keyMap: "sublime",
		spellcheck: true
            });
            
            area.id = "old_#{field_id}";
            editor.getInputField().id = "#{field_id}";

            // To make sure the TextArea is updated for the preview function, TODO: hook into preview logic
            editor.on('change',function(cm){
              cm.save();
            });
		
	    // FIX: sizing issue when div was first hidden
            editor.on('focus', function(){
		editor.refresh();
	    });

            var editorWrapper = editor.getWrapperElement();

            $(editorWrapper).resizable({
              resize: function() {
                editor.setSize($(this).width(), $(this).height());
                editor.refresh();
              }
            });
            var wikiToolbar = new jsToolBar(editor);
            wikiToolbar.setHelpLink('#{escape_javascript url}');
            wikiToolbar.draw();

	    $('#issue_description_and_toolbar').siblings('a').click(function() {
	      window.setTimeout(function() {
	        $('#issue_description_and_toolbar').children('.CodeMirror')[0].CodeMirror.refresh()
	      }, 100);
            });
			});
          ))
        end
      end
    end
  end

  class Hooks < Redmine::Hook::ViewListener
	def view_layouts_base_body_bottom(context={})
      if context[:hook_caller].instance_variable_get(:@heads_for_codemirror_included)
		s = ''
		s += javascript_include_tag(:jstoolbar_codemirror, plugin: 'redmine_sublime_markdown_codemirror')
		s += javascript_include_tag("jstoolbar/markdown")
		s += javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}")
		s += javascript_include_tag(:codemirror, plugin: 'redmine_sublime_markdown_codemirror')
		s += javascript_include_tag(:markdown, plugin: 'redmine_sublime_markdown_codemirror')
		s += javascript_include_tag(:overlay, plugin: 'redmine_sublime_markdown_codemirror')
		s += javascript_include_tag(:sublime, plugin: 'redmine_sublime_markdown_codemirror')
		s += stylesheet_link_tag(:codemirror, plugin: 'redmine_sublime_markdown_codemirror')
		s += stylesheet_link_tag('jstoolbar')
		s.html_safe
      end
	end
  end
end


unless Redmine::WikiFormatting::Markdown::Helper.included_modules.include?(RedmineSublimeMarkdownCodeMirror::Patches::MarkdownHelperPatch)
  Redmine::WikiFormatting::Markdown::Helper.send(:include, RedmineSublimeMarkdownCodeMirror::Patches::MarkdownHelperPatch)
end
