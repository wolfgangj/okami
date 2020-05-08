# wok.rb - bootstrapping implementation of the compiler
# Copyright (C) 2019, 2020 Wolfgang Jährling
#
# ISC License
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# require 'byebug'

class Token
  def initialize(type, text, filename, line)
    @type = type
    @text = text
    @filename = filename
    @line = line
  end

  def special?(kind)
    @type == :special && @text == kind
  end

  def key?(kind)
    @type == :key && @text == kind
  end

  def type
    @type
  end

  def text
    @text
  end

  def pos
    "#{@filename}:#{@line}"
  end

  def to_s
    "#{@type} #{@text}"
  end
end

class Lexer
  def initialize(filename)
    @filename = filename
    @line = 1
    @src = File.open(filename)
    @ahead = nil
  end

  def next_token
    if @ahead
      res = @ahead
      @ahead = nil
      res
    else
      read_token()
    end
  end

  def peek_token
    @ahead = next_token()
    @ahead
  end

  private

  def getc
    res = @src.getc()
    if res == "\n"
      @line = @line + 1
    end
    res
  end

  def peekc
    res = @src.getc()
    @src.ungetc(res) if res
    res
  end

  def first_relevant
    while true
      c = getc() # may be nil
      return c unless irrelevant_char?(c)
      if c == ';'
        while c != "\n" # ignores possible eof
          c = getc()
        end
      end
    end
  end

  def special_token_char?(c)
    ['@', '^', '(', ')', '[', ']', '{', '}', ','].include?(c)
  end

  def irrelevant_char?(c)
    [" ", "\t", "\n", ";"].include?(c)
  end

  def identifier_char?(c)
    !special_token_char?(c) && !irrelevant_char?(c) &&
      !['#', '$', '%', '&', '|', '"', ':', '.'].include?(c)
  end

  def read_token
    c = first_relevant()
    case c
    when ->(c) { special_token_char?(c) }
      return Token.new(:special, c, @filename, @line)
    when '"'
      return nil # TODO
    when '$'
      return nil # TODO
    when ':'
      c = getc()
      raise "#{@filename}:#{@line}: syntax error - single colon" if c != ':'
      return Token.new(:special, '::', @filename, @line)
    when nil
      return Token.new(:eof, '', @filename, @line)
    else
      tok = c
      while identifier_char?(peekc())
        tok = tok + getc()
      end
      if tok[/^-?\d+$/]
        return Token.new(:int, tok, @filename, @line)
      end
      if peekc() == ':'
        getc() # read the colon
        return Token.new(:key, tok, @filename, @line) 
      end
      return Token.new(:id, tok, @filename, @line)
    end
  end

end


class Parser

  def initialize(filename)
    @lex = Lexer.new(filename)
  end

  def next_toplevel
    tok = initial()
    return nil if tok == nil

    case tok.text
    when 'the'
      return parse_variable()
    when 'dec'
      return parse_declaration()
    when 'def'
      return parse_definition()
    when 'for'
      # TODO
    when 'private'
      # TODO
    when 'public'
      # TODO
    when 'class'
      # TODO
    when 'enum'
      # TODO
    when 'union'
      # TODO
    when 'use'
      # TODO
    when 'primitive'
      # TODO
    else
      raise "#{tok.pos}: syntax error - unknown toplevel command #{tok.text}"
    end
  end

  private

  def initial
    tok = next_token()
    return nil if tok.type == :eof
    if tok.type != :id
      raise "#{@tok.pos}: syntax error - unexpected token #{tok.to_s} at toplevel"
    end
    tok
  end

  def next_token
    @lex.next_token()
    # TODO: if token was a macro, expand it here
  end

  def parse_variable
    name = next_token
    if name.type != :key
      raise "#{name.pos}: syntax error - expected 'varname:' after def, found #{name.text}"
    end

    type = parse_type()
    if type.is_a?(WokAdr)
      # we don't have the location of the *type* itself
      raise "#{name.pos}: @address not allowed as toplevel definition"
    end
    WokVar.new(name.text, type, name.pos)
  end

  def parse_declaration
    name = next_token()
    if name.type != :id
      raise "#{name.pos}: syntax error - expected identifier after dec, found #{name.text}"
    end

    effect = parse_effect()
    WokDec.new(name.text, effect, name.pos)
  end

  def parse_definition
    name = next_token()
    if name.type != :id
      raise "#{name.pos}: syntax error - expected identifier after def, found #{name.text}"
    end

    effect = parse_effect()
    code = parse_block()

    WokDef.new(name.text, effect, code, name.pos)
  end

  def parse_effect
    tok = next_token()
    if !tok.special?('(')
      raise "#{tok.pos}: expected '(', found #{tok.to_s}"
    end

    from = []
    loop do
      tok = @lex.peek_token # TODO: ignores macros
      if tok.special?('::')
        tok = @lex.next_token # skip past the '::'
        break
      end
      if tok.special?(')')
        break  # leave the ')' here
      end
      type = parse_type
      from << type
    end

    to = []
    loop do
      tok = @lex.peek_token # TODO: ignores macros
      if tok.special?(')')
        tok = @lex.next_token # skip past the ')'
        break
      end
      type = parse_type
      to << type
    end

    Effect.new(from, to)
  end

  def parse_block
    tok = next_token()
    if !tok.special?('[')
      raise "#{tok.pos}: expected '[', found #{tok.to_s}"
    end

    code = []
    loop do
      tok = next_token()
      break if tok.special?(']')

      case tok.type
      when :id
        code << OpCall.new(tok.text, tok.pos)
      when :special
        case tok.text
        when '@'
          code << OpCall.new('@', tok.pos)
        when ','
          code << OpCall.new(',', tok.pos)
        when '('
          # TODO: type cast
        else
          raise "#{tok.pos}: expected code, found #{tok.to_s}"
        end
      when :int
        code << OpPushInt.new(tok.text.to_i)
      when :key
        case tok.text
        when 'if'
          code << parse_if()
        when 'has'
          # TODO
        when 'loop'
          # TODO
        when 'new'
          # TODO
        when 'is'
          # TODO
        else
          raise "#{tok.pos}: expected code, found #{tok.to_s}"
        end
      else
        raise "#{tok.pos}: expected code, found #{tok.to_s}"
      end
    end
    code
  end

  def parse_type
    tok = next_token
    case tok.type
    when :id
      return WokTypeName.new(tok.text)
    when :special
      case tok.text
      when '@'
        return WokAdr.new(parse_type)
      when '^'
        # TODO
      when '['
        # TODO
      when '('
        # TODO
      else
        raise "#{tok.pos}: syntax error: expected type, found #{tok.to_s}"
      end
    else
      raise "#{tok.pos}: syntax error: expected type, found #{tok.to_s}"
    end
  end

  def parse_if
    then_branch = parse_block()
    tok = @lex.peek_token() # TODO: ignores macros
    if tok.key?('else')
      tok = next_token()
      else_branch = parse_block()
      OpIfElse.new(then_branch, else_branch)
    else
      OpIf.new(then_branch)
    end
  end

end

class WokVar
  def initialize(name, type, pos)
    @name = name
    @type = type
    @pos = pos
  end

  def name
    @name
  end
  def type
    @type
  end
  def pos
    @pos
  end
end

class WokDec
  def initialize(name, effect, pos)
    @name = name
    @effect = effect
    @pos = pos
  end

  def name
    @name
  end
  def effect
    @effect
  end
  def pos
    @pos
  end
end

class WokDef
  def initialize(name, effect, code, pos)
    @name = name
    @effect = effect
    @code = code
    @pos
  end

  def name
    @name
  end
  def effect
    @effect
  end
  def code
    @code
  end
  def pos
    @pos
  end
end

class WokAdr
  def initialize(type)
    @type = type
  end

  def type
    @type
  end
end

class WokTypeName
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end

class Effect
  # from and to are arrays of WokType
  def initialize(from, to)
    @from = from
    @to = to
  end

  def from
    @from
  end

  def to
    @to
  end
end

class OpCall
  def initialize(name, pos)
    @name = name
    @pos = pos
  end

  def name
    @name
  end
  def pos
    @pos
  end
end

class OpIfElse
  def initialize(then_code, else_code)
    @then_code = then_code
    @else_code = else_code
  end

  def then_code
    @then_code
  end
  def else_code
    @else_code
  end
end

class OpIf
  def initialize(then_code)
    @then_code = then_code
  end

  def then_code
    @then_code
  end
end

class OpPushInt
  def initialize(i)
    @i = i
  end

  def i
    @i
  end
end

class Generator
  def initialize(module_name)
    @module_name = module_name
    @current_module = WokModule.new()
    @parser = Parser.new(module_name + '.wok')
    @next_label_nr = 0
  end

  def compile
    emit('%include "../runtime/wok-codes.asm"')
    loop do
      toplevel = @parser.next_toplevel
      break if toplevel == nil
      case toplevel
      when WokVar
        register(toplevel)
        emit_var(toplevel)
      when WokDec
        register(toplevel)
      when WokDef
        register(toplevel)
        emit_def(toplevel)
      end
    end
  end

  private

  def register(toplevel_entry)
    # can be WokVar, WokDec, WokDef
    @current_module.register(toplevel_entry.name, toplevel_entry)
  end

  def emit_var(var)
    emit('section .bss')
    emit(mangle(var.name) + ': resq 1')
  end

  def emit_def(wok_def)
    emit('section .text')
    emit('global ' + mangle(wok_def.name))
    emit(mangle(wok_def.name) + ':')
    emit_codeblock(wok_def.code)
    emit('wok_ok')
  end

  def emit_codeblock(code)
    code.each do |element|
      case element
      when OpCall    then emit_call(element)
      when OpIf      then emit_if(element)
      when OpIfElse  then emit_eif(element)
      when OpPushInt then emit_push_int(element)
      end
    end
  end

  def emit_call(call)
    case call.name
    when '@'
      emit('wok_at_64')
    when 'this', 'that', 'alt', 'nip', 'tuck', 'them', 'dropem',
         'and', 'or', 'xor', 'not', 'self', 'idx', 'mod'
      emit('wok_' + call.name)
    when ','
      emit('wok_drop')
    when '+'
      emit('wok_plus')
    when '-'
      emit('wok_minus')
    when '*'
      emit('wok_mul')
    when '/'
      emit('wok_div')
    when '!'
      emit('wok_store_64')
    when '='
      emit('wok_is_eq')
    when '<>'
      emit('wok_is_ne')
    when '>'
      emit('wok_is_gt')
    when '<'
      emit('wok_is_lt')
    when '>='
      emit('wok_is_ge')
    when '<='
      emit('wok_is_le')
    when '=0'
      emit('wok_eq0')
    when '<>0'
      emit('wok_neq0')
    when 'shift<'
      emit('wok_shift_left')
    when 'shift>'
      emit('wok_shift_right')
    when 'ashift>'
      emit('wok_ashift_right')
    else
      target = @current_module.lookup(call.name)
      case target
      when WokVar
        emit('wok_var ' + mangle(call.name))
      when WokDef, WokDec
        emit('call ' + mangle(call.name))
      when nil
        raise "#{call.pos}: #{call.name} was not defined"
      else
        raise "#{call.pos}: #{call.name} previously defined as something other than a var or def"
      end
    end
  end

  def emit_if(wok_if)
    end_label = next_label()
    emit('wok_if_check ' + end_label)
    emit_codeblock(wok_if.then_code)
    emit('wok_if_end ' + end_label)
  end

  def emit_eif(eif)
    else_label = next_label()
    end_label = next_label()
    emit('wok_eif_check ' + else_label)
    emit_codeblock(eif.then_code)
    emit('wok_eif_else ' + end_label + ', ' + else_label)
    emit_codeblock(eif.else_code)
    emit('wok_eif_end ' + end_label)
  end

  def emit_push_int(int)
    if int.i == 0
      emit('wok_const_0')
    else
      emit('wok_const_int ' + int.i.to_s)
    end
  end

  def mangle(name)
    name.
      gsub('-','__').
      gsub('+','_P').
      gsub('!','_B').
      gsub('*','_A').
      gsub('=','_E').
      gsub('<','_L').
      gsub('>','_G').
      gsub('?','_Q').
      gsub('/','_S')
  end

  def emit(str)
    puts str # TODO
  end

  def next_label
    @next_label_nr += 1
    '.L' + @next_label_nr.to_s
  end

end

class WokModule
  def initialize
    @content = {}
  end

  def lookup(name)
    @content[name]
  end

  def register(name, value)
    old = lookup(name)
    if old != nil
      if old.is_a?(WokDec)
        # TODO: check if it's a dec or def now with the same effect
      else
        raise "#{value.pos}: #{name} previously defined at #{old.pos}"
      end
    end
    @content[name] = value
  end
end

gen = Generator.new(ARGV[0])
gen.compile()

