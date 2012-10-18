#!/usr/bin/env ruby 
#

require 'statemachine'

class GolangRegex
	GOLANG_IMPORT_SINGLE=/^\s*import[^\"\/]+\"(?<importpath>.*?)\"/
  GOLANG_IMPORT_START=/^\s*import\s*\(/  
  GOLANG_IMPORT_PATH=/(?<!\/\/)(?:[^\"\/]*\"(?<importpath>.*?)\")/ 
  GOLANG_IMPORT_END=/\)/
  GOLANG_COMMENT_START=/\/\*/
  GOLANG_COMMENT_END=/\*\//
  
  def self.match_import_single(line)
    GOLANG_IMPORT_SINGLE.match(line)
  end
  
  def self.match_import_start(line)
    GOLANG_IMPORT_START.match(line)
  end
  
  def self.match_import_end(line)
    GOLANG_IMPORT_END.match(line)
  end

  def self.match_import_path(line)
    GOLANG_IMPORT_PATH.match(line)
  end

  def self.match_comment_start(line)  
    GOLANG_COMMENT_START.match(line)
  end

  def self.match_comment_end(line)
    GOLANG_COMMENT_END.match(line)
  end

end

class GolangParserContext
  attr_reader :import_paths
  attr_accessor :statemachine
  
  def initialize(file_path)
    @file_path = file_path
    @import_paths = []    
  end
   
  def start_parsing
    # open file and read lines until we're done
    puts "start parsing file #{@file_path}"
    File.open(@file_path).each do |line|
      statemachine.parse_line(line)
      break if statemachine.state == :finished
    end
  end
    
  def parse_before_import_line(line)
    comment = CommentHandler.new(line)
    if match = GolangRegex::match_import_single(comment.code_line)
      @import_paths << match['importpath']
    	parse_before_import_line(match.post_match) if match.post_match
    elsif match = GolangRegex::match_import_start(comment.code_line)
      statemachine.import_start
      parse_import_line(match.post_match) if match.post_match
    end
    comment.post_process(statemachine)
  end
  
  def parse_import_line(line)
    comment = CommentHandler.new(line)
    if check_for_import_end(comment.code_line)
      statemachine.import_end
      return
    end
    if match = GolangRegex::match_import_path(comment.code_line)
      @import_paths << match['importpath']
      statemachine.parse_line(match.post_match) if match.post_match
    end
    comment.post_process(statemachine)
  end
  
  # nb. this will trip up on nested comment blocks
  def parse_comment_line(line)
    if match = GolangRegex::match_comment_end(line)
      statemachine.exit_comment
      statemachine.parse_line(match.post_match) if match.post_match
    end
  end
  
  def in_import
    puts "entering import section"
  end
  
  def comment_enter
    puts "entering comment block"
  end
  
  def comment_exit
    puts "leaving comment block"
  end
  
  def complete
    puts "parsing #{@file_path} complete"    
  end
  
  private
  
  def check_for_import_end(line)
    line =~ GolangRegex::GOLANG_IMPORT_END 
  end
  
end

# helper to hold state when encountering an
# opening multiline comment
class CommentHandler
  
  def initialize(line)
    @line = line
    @match = GolangRegex::match_comment_start(line)
  end
  
  def entering_comment
    @match
  end
  
  def code_line
    return @match ? @match.pre_match : @line
  end
  
  def post_process(statemachine)
    if @match
      statemachine.enter_comment
      statemachine.parse_line(@match.post_match) if @match.post_match
    end    
  end
  
end

class GolangParser

  # parses the go source file specified by file_path and
  # returns an array of importpaths
  #
  def get_import_paths(file_path)
    
    parser_context = GolangParserContext.new(file_path)
    
    parser = Statemachine.build do  # order is important here
      
      superstate :parsing_code do
  
        # initial state
        state :initialized do
          # event -> new state ( + action)
          event :start, :starting
        end
        
        # intermediate state to kick-off parsing 
        # (allows :begin_import to be reentrant)
        state :starting do
          event :parse_line,    :before_import,  :parse_before_import_line
          on_entry :start_parsing
        end
      
        # parsing before a block import statement
        state :before_import do
          event :parse_line,    :before_import, :parse_before_import_line
          event :import_start,  :in_import
        end
  
        # parsing inside a block import statement
        state :in_import do
          event :parse_line,    :in_import,     :parse_import_line
          event :import_end,    :finished,      :complete
          on_entry :in_import
        end
        event :enter_comment, :commented, :comment_enter
      end
      
      # parsing inside a comment block
      trans :commented, :exit_comment, :parsing_code_H, :comment_exit
      trans :commented, :parse_line, :commented, :parse_comment_line
      
      # set the context object
      context parser_context
      
    end
    
    parser.start 
    parser_context.import_paths
    
  end

end

