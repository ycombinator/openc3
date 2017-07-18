# encoding: ascii-8bit

# Copyright 2014 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt

require 'cosmos'
require 'cosmos/script'
require 'cosmos/config/config_parser'
require 'cosmos/gui/utilities/script_module_gui'
require 'cosmos/gui/dialogs/splash'
require 'cosmos/gui/dialogs/exception_dialog'
require 'cosmos/gui/text/completion'
require 'cosmos/gui/text/completion_line_edit'
require 'cosmos/gui/text/ruby_editor'
require 'cosmos/gui/dialogs/progress_dialog'
require 'cosmos/gui/dialogs/find_replace_dialog'
require 'cosmos/gui/choosers/file_chooser'
require 'cosmos/config/meta_config_parser'

module Cosmos
  class ConfigEditorFrame < Qt::Widget
    slots 'context_menu(const QPoint&)'
    slots 'undo_available(bool)'
    slots 'cursor_position_changed()'
    signals 'undoAvailable(bool)'
    signals 'modificationChanged(bool)'
    signals 'cursorPositionChanged()'

    attr_reader :filename
    attr_reader :editor

    @@file_number = 1

    def initialize(parent, default_tab_text = 'Untitled')
      super(parent)
      @default_tab_text = '  ' + default_tab_text + '  '
      # Keep track of whether this frame has been fully initialized
      @initialized = false

      # Keep track of a unique file number so we can differentiate untitled tabs
      @file_number = @@file_number
      @@file_number += 1
      @filename = ''

      @layout = Qt::VBoxLayout.new
      @layout.setContentsMargins(0,0,0,0)

      # Create a splitter to hold the config text area and the config GUI help
      @splitter = Qt::Splitter.new(Qt::Horizontal, self)
      @layout.addWidget(@splitter)
      @top_widget = Qt::Widget.new(@splitter)
      @top_widget.setContentsMargins(0,0,0,0)
      @top_frame = Qt::VBoxLayout.new(@top_widget)
      @top_frame.setContentsMargins(0,0,0,0)

      # Add Initial Text Window
      @editor = create_ruby_editor()
      @editor.filename = unique_filename()
      @editor.connect(SIGNAL('modificationChanged(bool)')) do |changed|
        emit modificationChanged(changed)
      end
      @editor.connect(SIGNAL('undoAvailable(bool)')) { |bool| undo_available(bool) }
      @editor.connect(SIGNAL('cursorPositionChanged()')) { cursor_position_changed() }
      @top_frame.addWidget(@editor)

      # Set self as the gui window to allow prompts and other popups to appear
      set_cmd_tlm_gui_window(self)

      # Add GUI Frame
      @gui_widget = Qt::Widget.new
      gui_layout = Qt::VBoxLayout.new
      gui_layout.setContentsMargins(5,0,0,0)
      gui_layout_label = Qt::Label.new("COSMOS Config File Help")
      gui_layout.addWidget(gui_layout_label)
      @gui_widget.setLayout(gui_layout)
      @gui_area = Qt::ScrollArea.new
      @gui_area.setWidgetResizable(true) # Key to allow sub widget to resize
      @gui_area.setWidget(@gui_widget)
      @splitter.addWidget(@gui_area)
      @splitter.setStretchFactor(0,10)
      @splitter.setStretchFactor(1,0)

      setLayout(@layout)

      # Configure Variables
      @key_press_callback = nil
      @output_time = Time.now.sys
      initialize_variables()

      # Create Tabbook
      @tab_book = Qt::TabWidget.new
      @tab_book_shown = false

      @find_dialog = nil
      @replace_dialog = nil
    end

    def unique_filename
      if @filename and !@filename.empty?
        return @filename
      else
        return @default_tab_text.strip + @file_number.to_s
      end
    end

    def create_ruby_editor
      script = RubyEditor.new(self)
      # Add right click menu
      script.setContextMenuPolicy(Qt::CustomContextMenu)
      connect(script,
              SIGNAL('customContextMenuRequested(const QPoint&)'),
              self,
              SLOT('context_menu(const QPoint&)'))
      script
    end

    def filename=(filename)
      @filename = filename
      determine_file_type()
    end

    def modified
      @editor.document.isModified()
    end

    def modified=(bool)
      @editor.document.setModified(bool)
    end

    def undo_available(bool)
      emit undoAvailable(bool)
    end

    def cursor_position_changed()
      emit cursorPositionChanged()
      display_keyword_help() if @display_help
    end

    def key_press(event)
      @display_help = true
      @key_press_callback.call(event)
      # Check for any kind of selection so we don't try to display help
      # Trying to display help during a selection breaks the selection due to
      # how we move the cursor to find the keywords
      if event.matches(Qt::KeySequence::SelectEndOfBlock) ||
        event.matches(Qt::KeySequence::SelectEndOfDocument) ||
        event.matches(Qt::KeySequence::SelectEndOfLine) ||
        event.matches(Qt::KeySequence::SelectNextChar) ||
        event.matches(Qt::KeySequence::SelectNextLine) ||
        event.matches(Qt::KeySequence::SelectNextPage) ||
        event.matches(Qt::KeySequence::SelectPreviousChar) ||
        event.matches(Qt::KeySequence::SelectPreviousLine) ||
        event.matches(Qt::KeySequence::SelectPreviousPage) ||
        event.matches(Qt::KeySequence::SelectPreviousWord) ||
        event.matches(Qt::KeySequence::SelectStartOfBlock) ||
        event.matches(Qt::KeySequence::SelectStartOfDocument) ||
        event.matches(Qt::KeySequence::SelectStartOfLine)
        @display_help = false
      end
      true # Always process the event
    end

    def key_press_callback=(callback)
      @key_press_callback = callback
      @editor.keyPressCallback = method(:key_press)
    end

    def setFocus
      @editor.setFocus
    end

    def clear
      self.set_text('')
      self.filename = ''
      @editor.filename = unique_filename()
      self.modified = false
    end

    def text
      @editor.toPlainText.gsub("\r", '')
    end

    def set_text(text, filename = '')
      @editor.setPlainText(text)
      @filename = filename
      @editor.filename = unique_filename()
    end

    def set_text_from_file(filename)
      load_file_into_script(filename)
      @filename = filename
    end

    ######################################
    # Implement edit functionality in the frame (cut, copy, paste, etc)
    ######################################
    def undo
      @editor.undo
    end

    def redo
      @editor.redo
    end

    def cut
      @editor.cut
    end

    def copy
      @editor.copy
    end

    def paste
      @editor.paste
    end

    def select_all
      @editor.select_all
    end

    def comment_or_uncomment_lines
      @editor.comment_or_uncomment_lines
    end

    def cursor
      @editor.textCursor
    end

    def line_number
      @editor.line_number
    end

    def column_number
      @editor.column_number
    end

    def current_line
      @editor.current_line
    end

    def line_keyword(line = current_line())
      return '' if line.nil? || line.strip.empty? || line.strip[0] == '#'
      line.strip.split(" ")[0]
    end

    def previous_keyword
      previous_line = @editor.previous_line
      line_keyword(previous_line)
    end

    def graceful_kill
      # Just to avoid warning
    end

    protected

    def determine_file_type
      if @filename.empty?
        @file_type = "unknown"
      else
        # Check for inside target directory
        if @filename.include?('/config/targets/')
          if @filename.split('/')[-3] == 'targets'
            if File.basename(@filename).include?('cmd_tlm_server')
              @file_type = 'cmd_tlm_server'
            elsif File.basename(@filename).include?('target')
              @file_type = 'target'
            else
              @file_type = 'unknown' #FileTypeDialog.new(%w(cmd_tlm_server.txt))
            end
          else
            if @filename.include?('/cmd_tlm/')
              if @filename.include?('cmd') || @filename.include?('command')
                @file_type = 'command'
              elsif @filename.include?('tlm') || @filename.include?('telemetry')
                @file_type = 'telemetry'
              end
            end
          end
        end
      end
      @file_meta = MetaConfigParser.load("#{@file_type}.yaml")
      display_keyword_help()
    end

    def display_keyword_help
      return unless @file_meta
      keyword = line_keyword()
      unless keyword.empty?
        build_help_frame(find_meta_keyword(@file_meta, keyword))
      else
        keyword = previous_keyword()
        if keyword.empty?
          build_blank_help(@file_meta)
        else
          meta = find_meta_keyword(@file_meta, keyword)
          @modifiers = meta['modifiers'] if meta && meta['modifiers']
          if @modifiers
            build_blank_help(@modifiers)
            @modifiers = nil
          else
            build_blank_help(@file_meta)
          end
        end
      end
      # elsif keyword == @current_keyword
      #   # do something?
      # if !meta
      #   @current_keyword = nil
      #   @gui_widget.dispose()
      #   return
      # end
    end

    def find_meta_keyword(meta, keyword)
      result = nil
      meta.each do |meta_keyword, data|
        if meta_keyword == keyword
          result = meta[keyword]
          break
        elsif data["modifiers"]
          @modifiers = data['modifiers']
          result = find_meta_keyword(data["modifiers"], keyword)
          break if result
        end
      end
      result
    end

    def build_blank_help(meta)
      @gui_widget.dispose()
      @gui_widget = Qt::Widget.new
      @gui_layout = Qt::VBoxLayout.new
      @gui_widget.setLayout(@gui_layout)

      info = Qt::Label.new("Available Keywords")
      info.setFont(Cosmos.getFont("Arial", 16, Qt::Font::Bold))
      @gui_layout.addWidget(info)

      keys = meta.keys
      value_widget = Qt::ComboBox.new()
      value_widget.addItems(keys)
      @gui_layout.addWidget(value_widget)

      summary = Qt::Label.new(meta[keys[0]]['summary'])
      summary.setFont(Cosmos.getFont("Arial", 12))
      summary.setWordWrap(true)
      @gui_layout.addWidget(summary)

      description = Qt::Label.new(meta[keys[0]]['description'])
      description.setFont(Cosmos.getFont("Arial", 9))
      description.setWordWrap(true)
      @gui_layout.addWidget(description)

      value_widget.connect(SIGNAL('currentIndexChanged(const QString&)')) do |word|
        summary.setText(meta[word]['summary'])
        description.setText(meta[word]['description'])
      end

      add_keyword = Qt::PushButton.new("Add Keyword")
      add_keyword.connect(SIGNAL('clicked()')) do
        insert_word(value_widget.text, nil) # nil means prepend
        display_keyword_help() # Regenerate the help
      end
      @gui_layout.addWidget(add_keyword)

      @gui_layout.addStretch
      @gui_area.setWidget(@gui_widget)
    end

    def build_help_frame(meta)
      return unless meta
      word = @editor.current_word
      @gui_widget.dispose()
      @gui_widget = Qt::Widget.new
      @gui_layout = Qt::VBoxLayout.new
      @gui_widget.setLayout(@gui_layout)

      @current_keyword = line_keyword()
      keyword = Qt::Label.new(@current_keyword)
      keyword.setFont(Cosmos.getFont("Arial", 16, Qt::Font::Bold))
      @gui_layout.addWidget(keyword)

      meta.each do |attribute_name, attribute_value|
        if attribute_name != 'parameters'
          case attribute_name
          when 'summary'
            summary = Qt::Label.new(attribute_value)
            summary.setFont(Cosmos.getFont("Arial", 12))
            summary.setWordWrap(true)
            @gui_layout.addWidget(summary)
          when 'description'
            description = Qt::Label.new(attribute_value)
            description.setFont(Cosmos.getFont("Arial", 9))
            description.setWordWrap(true)
            @gui_layout.addWidget(description)
          end
        else # Process parameters
          next if attribute_value.empty?
          line = Qt::Frame.new(@gui_widget)
          line.setFrameStyle(Qt::Frame::HLine | Qt::Frame::Sunken)
          @gui_layout.addWidget(line)
          param = Qt::Label.new("Parameters:")
          param.setFont(Cosmos.getFont("Arial", 14, Qt::Font::Bold))
          @gui_layout.addWidget(param)
          process_parameters(attribute_value)
        end
      end
      @gui_layout.addStretch
      @gui_area.setWidget(@gui_widget)
    end

    def process_parameters(parameters, parameter_offset = 1)
      line_parts = current_line.scan(ConfigParser::PARSING_REGEX)
      parameters.each_with_index do |parameter, parameter_index|
        parameter_index += parameter_offset
        name_layout = Qt::HBoxLayout.new
        description = Qt::Label.new()
        value_widget = Qt::Widget.new
        required = false
        parameter.each do |attribute_name, attribute_value|
          case attribute_name
          when 'name'
            param = Qt::Label.new(attribute_value)
            param.setFont(Cosmos.getFont("Arial", 12, Qt::Font::Bold))
            param.setWordWrap(true)
            name_layout.addWidget(param)
          when 'description'
            description.text = attribute_value
            description.setFont(Cosmos.getFont("Arial", 9))
            description.setWordWrap(true)
            @gui_layout.addWidget(description)
          when 'required'
            if attribute_value == true
              required = true
              required_label = Qt::Label.new("(Required)")
            else
              required = false
              required_label = Qt::Label.new("(Optional)")
            end
            required_label.setFont(Cosmos.getFont("Arial", 10))
            name_layout.addWidget(required_label)
            @gui_layout.addLayout(name_layout)
          when 'values'
            current_value = line_parts[parameter_index]
            if attribute_value.is_a? Hash
              # If the value is a Hash then we have parameter specific
              # parameters embedded in this parameter we have to parse
              value_widget = Qt::ComboBox.new()
              value_widget.addItem(current_value) unless attribute_value.keys.include?(current_value)
              value_widget.addItems(attribute_value.keys)
              value_widget.setCurrentText(current_value)
              value_widget.connect(SIGNAL('currentIndexChanged(const QString&)')) do |word|
                insert_word(word, parameter_index, -1)
                @current_keyword = nil # Clear the current keyword to force a re-layout
                display_keyword_help() # Rebuild the GUI since we may have new parameters
              end
              @gui_layout.addWidget(value_widget)
              if current_value && attribute_value[current_value]
                process_parameters(attribute_value[current_value]['parameters'], parameter_index + 1)
              end
            elsif attribute_value.is_a? Array # Just a bunch of strings
              value_widget = Qt::ComboBox.new()
              value_widget.addItems(attribute_value)
              if required && current_value.nil?
                value_widget.setStyleSheet("border: 1px solid red")
              end
              if current_value
                value_widget.addItem(current_value) unless attribute_value.include?(current_value)
                value_widget.setCurrentText(current_value)
              end
              value_widget.connect(SIGNAL('currentIndexChanged(const QString&)')) do |word|
                value_widget.setStyleSheet("")
                insert_word(word, parameter_index)
              end
              @gui_layout.addWidget(value_widget)
            else
              value_widget = Qt::LineEdit.new(current_value)
              if required && current_value.nil?
                value_widget.setStyleSheet("border: 1px solid red")
              end
              value_widget.connect(SIGNAL('editingFinished()')) do
                if value_widget.text =~ Regexp.new("^#{attribute_value}$")
                  value_widget.setStyleSheet("")
                  insert_word(value_widget.text, parameter_index)
                else
                  value_widget.setStyleSheet("border: 1px solid red")
                end
              end
              @gui_layout.addWidget(value_widget)
            end
          end
        end
      end
    end

    def insert_word(word, start_index, end_index = nil)
      @editor.blockSignals(true)
      c = @editor.textCursor
      current = @editor.current_line
      line_parts = current_line.scan(ConfigParser::PARSING_REGEX)
      indentation = current.length - current.lstrip.length
      if start_index.nil?
        #c.movePosition(Qt::TextCursor::StartOfLine)
        c.insertText(word)
      elsif start_index < line_parts.length
        end_index = start_index unless end_index
        line_parts[start_index..end_index] = word
        c.movePosition(Qt::TextCursor::StartOfLine)
        c.movePosition(Qt::TextCursor::EndOfLine, Qt::TextCursor::KeepAnchor)
        c.insertText("#{' '*indentation}#{line_parts.join(' ')}")
      elsif start_index >= line_parts.length || start_index == -1
        c.movePosition(Qt::TextCursor::EndOfLine)
        c.insertText(" #{word}")
      end
      # c.movePosition(Qt::TextCursor::EndOfLine)
      # @editor.setTextCursor(cursor)
      @editor.blockSignals(false)
      @editor.setFocus
    end

    def initialize_variables
      @active_script = @editor
      @current_file = @filename
      @current_filename = nil
    end

    def show_active_tab
      @tab_book.setCurrentIndex(@call_stack.length - 1) if @tab_book_shown
    end

    # Right click context_menu for the script
    def context_menu(point)
      if @tab_book_shown
        current_script = @tab_book.widget(@tab_book.currentIndex)
      else
        current_script = @editor
      end
      menu = current_script.context_menu(point)
      menu.exec(current_script.mapToGlobal(point))
      menu.dispose
    end

    def load_file_into_script(filename)
      @active_script.setPlainText(File.read(filename).gsub("\r", ''))
    end

    def create_tabs
      tab_text = @default_tab_text
      tab_text = '  ' + File.basename(@filename) + '  ' unless @filename.empty?
      @tab_book.addTab(@editor, tab_text)
      @top_frame.insertWidget(0, @tab_book)
      @tab_book_shown = true
    end

    def remove_tabs
      @top_frame.takeAt(0) # Remove the @tab_book from the layout
      @top_frame.addWidget(@editor) # Add back the script
      @editor.show
      @tab_book_shown = false
    end
  end
end
