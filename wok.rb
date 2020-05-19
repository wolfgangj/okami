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

#require 'byebug'

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

  def eof?
    @type == :eof
  end

  def str?
    @type == :str
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
    @ahead = []
  end

  def next_token
    if @ahead.empty?
      read_token()
    else
      @ahead.shift()
    end
  end

  def peek_token
    res = next_token()
    @ahead.unshift(res)
    res
  end

  def insert_tokens(tokens)
    @ahead.concat(tokens)
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
    loop do
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
      text = ''
      loop do
        c = getc()
        break if c == '"'
        if c == '\\'
          c = getc()
          case c
          when 'n' then c = "\n"
          when 't' then c = "\t"
          end
        end
        text += c
      end
      return Token.new(:str, text, @filename, @line)
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
        if peekc() != ':'
          return Token.new(:key, tok, @filename, @line) 
        else
          getc() # read second colon
          @ahead.unshift(Token.new(:special, '::', @filename, @line))
        end
      end
      return Token.new(:id, tok, @filename, @line)
    end
  end

end


class Parser

  def initialize(filename, mod)
    @lex = Lexer.new(filename)
    @mod = mod # need module for looking up macros
  end

  def next_toplevel
    tok = initial() # returns nil or id-token
    return nil if tok == nil

    case tok.text
    when 'the'
      return parse_variable()
    when 'dec'
      return parse_declaration()
    when 'def'
      return parse_definition()
    when 'for'
      return parse_macro()
    when 'private'
      # TODO
    when 'public'
      # TODO
    when 'class'
      # TODO
    when 'opt'
      # TODO
    when 'use'
      # TODO
    when 'type'
      return parse_primitive_type()
    else
      raise "#{tok.pos}: syntax error - unknown toplevel command #{tok.text}"
    end
  end

  private

  def initial
    tok = next_token()
    return nil if tok.eof?
    if tok.type != :id
      raise "#{tok.pos}: syntax error - unexpected token #{tok.to_s} at toplevel"
    end
    tok
  end

  def next_token
    tok = @lex.next_token()
    if tok.type == :id
      mac = @mod.lookup(tok.text)
      if mac.is_a?(WokFor)
        @lex.insert_tokens(mac.tokens)
        return next_token()
      end
    end
    tok
  end

  def parse_primitive_type
    name = next_token()
    if name.type != :key
      raise "#{name.pos}: syntax error - expected `typename:` after 'type', found #{name.text}"
    end
    old_name = next_token()
    if old_name.type != :id
      raise "#{name.pos}: syntax error - expected typename identifier as type reference, found #{name.text}"
    end
    TypeDef.new(name.text, name.pos, old_name.text)
  end

  def parse_variable
    name = next_token()
    if name.type != :key
      raise "#{name.pos}: syntax error - expected 'varname:' after def, found #{name.text}"
    end

    type = parse_type()
    if type.is_a?(WokAdr)
      raise "#{name.pos}: @address not allowed as toplevel definition"
    end
    WokVar.new(name.text, type, name.pos)
  end

  def parse_macro
    name = next_token()
    if name.type != :id
      raise "#{name.pos}: syntax error - expected identifier after for, found #{name.text}"
    end

    curly = next_token()
    if !curly.special?('{')
      raise "#{name.pos}: syntax error - expected opening curly brace, found #{curly.to_s}"
    end

    tokens = []
    curly = 0
    loop do
      tok = next_token()
      if tok.eof?
        # using the name pos might actually be a good idea here in
        # case the user forgets to close a macro
        raise "#{name.pos}: syntax error - eof in macro definition"
      end
      if tok.special?('}')
        if curly == 0
          break
        else
          curly -= 1
        end
      end
      if tok.special?('{')
        curly += 1
      end
      tokens << tok
    end

    WokFor.new(name.text, tokens, name.pos)
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
          @lex.insert_tokens([tok]) # for parse_effect()
          code << OpCast.new(parse_effect(), tok.pos)
        else
          raise "#{tok.pos}: expected code, found #{tok.to_s}"
        end
      when :int
        code << OpPushInt.new(tok.text.to_i)
      when :str
        code << OpPushStr.new(tok.text)
      when :key
        case tok.text
        when 'if'
          code << parse_if(tok.pos)
        when 'has'
          code << parse_has(tok.pos)
        when 'loop'
          code << parse_loop(tok.pos)
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
      return WokTypeName.new(tok.text, tok.pos)
    when :special
      case tok.text
      when '@'
        return WokAdr.new(parse_type())
      when '^'
        return WokPtr.new(parse_type())
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

  def parse_has(pos)
    then_branch = parse_block()
    tok = @lex.peek_token() # TODO: ignores macros
    if tok.key?('else')
      tok = next_token()
      else_branch = parse_block()
      OpHas.new(then_branch, else_branch, pos)
    else
      OpHas.new(then_branch, [], pos)
    end
  end

  def parse_if(pos)
    then_branch = parse_block()
    tok = @lex.peek_token() # TODO: ignores macros
    if tok.key?('else')
      tok = next_token()
      else_branch = parse_block()
      OpIfElse.new(then_branch, else_branch, pos)
    else
      OpIf.new(then_branch, pos)
    end
  end

  def parse_loop(pos)
    code = parse_block()
    OpLoop.new(code, pos)
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
    @pos = pos
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

class WokFor
  def initialize(name, tokens, pos)
    @name = name
    @tokens = tokens
    @pos = pos
  end

  def name
    @name
  end
  def tokens
    @tokens
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

  def to_s
    "@#{@type.to_s}"
  end
end

class WokPtr
  def initialize(type)
    @type = type
  end

  def type
    @type
  end

  def to_s
    "^#{@type.to_s}"
  end
end

class WokTypeName
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

  def to_s
    name()
  end
end

class Effect
  # from and to are arrays of WokType
  def initialize(from, to)
    @from = from.freeze
    @to = to.freeze
  end

  def from
    @from
  end

  def to
    @to
  end

  def to_s
    "(#{@from.map(&:to_s).join(' ')} :: #{@to.map(&:to_s).join(' ')})"
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
  def initialize(then_code, else_code, pos)
    @then_code = then_code
    @else_code = else_code
    @pos = pos
  end

  def then_code
    @then_code
  end
  def else_code
    @else_code
  end
  def pos
    @pos
  end
end

class OpIf
  def initialize(then_code, pos)
    @then_code = then_code
    @pos = pos
  end

  def then_code
    @then_code
  end
  def pos
    @pos
  end
end

class OpHas
  def initialize(then_code, else_code, pos)
    @then_code = then_code
    @else_code = else_code
    @pos = pos
  end

  def then_code
    @then_code
  end
  def else_code
    @else_code
  end
  def pos
    @pos
  end
end

class OpLoop
  def initialize(code, pos)
    @code = code
    @pos = pos
  end

  def code
    @code
  end
  def pos
    @pos
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

class OpPushStr
  def initialize(text)
    @text = text
  end

  def text
    @text
  end
end

class Compiler
  def initialize(module_name)
    @module_name = module_name
    @current_module = WokModule.new()
    @parser = Parser.new(module_name + '.wok', @current_module)
    @next_label_nr = 0
    @types = Types.new()
    builtin_type('any')
    builtin_type('int')
    builtin_type('bool')
    builtin_type('s32', size: 32, signed: true)
    builtin_type('s16', size: 16, signed: true)
    builtin_type('s8', size: 8, signed: true)
    builtin_type('u32', size: 32, signed: false)
    builtin_type('u16', size: 16, signed: false)
    builtin_type('u8', size: 8, signed: false)

    @loop_end_labels = []
    @loop_end_stacks = []
  end

  def compile
    emit('%include "../runtime/wok-codes.asm"')
    loop do
      toplevel = @parser.next_toplevel
      break if toplevel == nil
      case toplevel
      when WokVar
        verify_type(toplevel.type)
        register(toplevel)
        emit_var(toplevel)
      when WokDec
        verify_effect_types(toplevel.effect)
        register(toplevel)
        # TODO: only for declarations from interface files:
        emit_dec(toplevel)
      when WokDef
        verify_effect_types(toplevel.effect)
        register(toplevel)
        emit_def(toplevel)
      when WokFor
        register(toplevel)
      when TypeDef
        old = @types.lookup(toplevel.old)
        if old == nil
          raise "#{toplevel.pos}: unknown type #{toplevel.old}"
        end
        @types.register(toplevel.name, PrimitiveType.new(toplevel.name, toplevel.pos, old.size, old.signed))
      end
    end
  end

  private

  def register(toplevel_entry)
    # can be WokVar, WokDec, WokDef, WokFor
    @current_module.register(toplevel_entry.name, toplevel_entry)
  end

  def builtin_type(name, size: :native, signed: true)
    @types.register(name, PrimitiveType.new(name, '(builtin)', size, signed))
  end

  def emit_dec(dec)
    emit('extern ' + mangle(dec.name))
  end

  def emit_var(var)
    size = :native
    if var.type.is_a?(WokTypeName)
      type = @types.lookup(var.type.name)
      size = type.size
    end
    emit("wok_the#{size} #{mangle(var.name)}, 1")
  end

  def emit_def(wok_def)
    @stack = WokStack.new(wok_def.effect.from.dup, @types)
    emit('section .text')
    emit('global ' + mangle(wok_def.name))
    emit(mangle(wok_def.name) + ':')
    emit_codeblock(wok_def.code)
    emit('wok_ok')
    if !@stack.can_use_stack?(as: wok_def.effect.to)
      raise "#{wok_def.pos}: code results in #{@stack}, should be #{WokStack.new(wok_def.effect.to, nil)}"
    end
  end

  def emit_codeblock(code)
    code.each do |element|
      case element
      when OpCall    then emit_call(element)
      when OpIf      then emit_if(element)
      when OpIfElse  then emit_eif(element)
      when OpHas     then emit_has(element)
      when OpPushInt then emit_push_int(element)
      when OpPushStr then emit_push_str(element)
      when OpLoop    then emit_loop(element)
      when OpCast    then perform_cast(element)
      end
    end
  end

  def emit_call(call)
    case call.name
    when '@'
      kind = @stack.at(call.pos)
      if kind.is_a?(WokTypeName)
        type = @types.lookup(kind.name)
        case "#{type.signed}#{type.size}"
        when 'true32'
          emit('wok_at_s32')
        when 'true16'
          emit('wok_at_s16')
        when 'true8'
          emit('wok_at_s8')
        when 'false32'
          emit('wok_at_u32')
        when 'false16'
          emit('wok_at_u16')
        when 'false8'
          emit('wok_at_u8')
        else
          emit('wok_at_native')
        end
      else
        emit('wok_at_native')
      end
      @stack.push(kind)
    when 'this'
      @stack.this(call.pos)
      emit('wok_this')
    when 'that'
      @stack.that(call.pos)
      emit('wok_that')
    when 'alt'
      @stack.alt(call.pos)
      emit('wok_alt')
    when 'nip'
      @stack.nip(call.pos)
      emit('wok_nip')
    when 'tuck'
      @stack.tuck(call.pos)
      emit('wok_tuck')
    when 'them'
      @stack.them(call.pos)
      emit('wok_them')
    when 'dropem'
      @stack.dropem(call.pos)
      emit('wok_dropem')
    when 'and'
      @stack.wok_and(call.pos)
      emit('wok_and')
    when 'or'
      @stack.wok_or(call.pos)
      emit('wok_or')
    when 'xor'
      @stack.wok_xor(call.pos)
      emit('wok_xor')
    when 'not'
      @stack.wok_not(call.pos)
      emit('wok_not')
    when 'self'
      @stack.self(call.pos)
      emit('wok_self')
    when 'idx'
      @stack.idx(call.pos)
      emit('wok_idx')
    when 'mod'
      @stack.mod(call.pos)
      emit('wok_mod')
    when ','
      @stack.drop(call.pos)
      emit('wok_drop')
    when '+'
      @stack.plus(call.pos)
      emit('wok_add')
    when '-'
      @stack.minus(call.pos)
      emit('wok_sub')
    when '*'
      @stack.mul(call.pos)
      emit('wok_mul')
    when '/'
      @stack.div(call.pos)
      emit('wok_div')
    when '!'
      kind = @stack.bang(call.pos)
      if kind.is_a?(WokTypeName)
        type = @types.lookup(kind.name)
        case type.size
        when 32
          emit('wok_store_32')
        when 16
          emit('wok_store_16')
        when 8
          emit('wok_store_8')
        else
          emit('wok_store_native')
        end
      else
        emit('wok_store_native')
      end
    when '='
      @stack.is_eq(call.pos)
      emit('wok_is_eq')
    when '<>'
      @stack.is_ne(call.pos)
      emit('wok_is_ne')
    when '>'
      @stack.is_gt(call.pos)
      emit('wok_is_gt')
    when '<'
      @stack.is_lt(call.pos)
      emit('wok_is_lt')
    when '>='
      @stack.is_ge(call.pos)
      emit('wok_is_ge')
    when '<='
      @stack.is_le(call.pos)
      emit('wok_is_le')
    when '=0'
      @stack.eq0(call.pos)
      emit('wok_is_eq0')
    when '<>0'
      @stack.neq0(call.pos)
      emit('wok_is_neq0')
    when 'shift<'
      @stack.shift_left(call.pos)
      emit('wok_shift_left')
    when 'lshift>'
      @stack.lshift_right(call.pos)
      emit('wok_lshift_right')
    when 'ashift>'
      @stack.ashift_right(call.pos)
      emit('wok_ashift_right')
    when 'break'
      emit_break(call.pos)
    else
      target = @current_module.lookup(call.name)
      case target
      when WokVar
        emit('wok_var ' + mangle(call.name))
        @stack.push(WokAdr.new(target.type))
      when WokDef, WokDec
        @stack.apply(target.effect, call.pos)
        emit('call ' + mangle(call.name))
      when nil
        raise "#{call.pos}: #{call.name} was not defined"
      else
        raise "#{call.pos}: #{call.name} previously defined as something other than a var or def"
      end
    end
  end

  def emit_if(wok_if)
    @stack.pop_bool(wok_if.pos)

    orig_stack = @stack.dup

    end_label = next_label()
    emit('wok_if_check ' + end_label)
    emit_codeblock(wok_if.then_code)
    emit('wok_if_end ' + end_label)

    if !@stack.compat_branches?(orig_stack)
      raise "#{wok_if.pos}: stack after then-branch: #{@stack}, stack after else-branch: #{orig_stack}"
    end
    @stack.merge(orig_stack)
  end

  def emit_eif(eif)
    @stack.pop_bool(eif.pos)

    else_stack = @stack.dup

    else_label = next_label()
    end_label = next_label()
    emit('wok_eif_check ' + else_label)
    emit_codeblock(eif.then_code)

    # switch stack for else-branch
    then_stack = @stack
    @stack = else_stack

    emit('wok_eif_else ' + end_label + ', ' + else_label)
    emit_codeblock(eif.else_code)
    emit('wok_eif_end ' + end_label)

    if !@stack.compat_branches?(then_stack)
      raise "#{eif.pos}: stack after then-branch: #{then_stack}, stack after else-branch: #{@stack}"
    end
    @stack.merge(then_stack)
  end

  def emit_has(has)
    ptr_type = @stack.pop(has.pos)
    if !ptr_type.is_a?(WokPtr)
      raise "#{has.pos}: expected pointer for 'has:', got #{ptr_type}"
    end

    else_stack = @stack.dup
    @stack.push(WokAdr.new(ptr_type.type))

    else_label = next_label()
    end_label = next_label()
    emit('wok_has_check ' + else_label)
    emit_codeblock(has.then_code)

    # switch stack for else-branch
    then_stack = @stack
    @stack = else_stack

    emit('wok_has_else ' + end_label + ', ' + else_label)
    emit_codeblock(has.else_code)
    emit('wok_has_end ' + end_label)

    if !@stack.compat_branches?(then_stack)
      raise "#{eif.pos}: stack after then-branch: #{then_stack}, stack after else-branch: #{@stack}"
    end
    @stack.merge(then_stack)
  end

  def emit_loop(wok_loop)
    start_label = next_label()
    end_label = next_label()
    @loop_end_labels << end_label
    end_stack = WokStack.new([], @types)
    end_stack.stop!
    @loop_end_stacks << end_stack
    start_stack = @stack.dup

    emit('wok_loop_start ' + start_label)
    emit_codeblock(wok_loop.code)
    emit('wok_loop_end ' + start_label + ', ' + end_label)

    # TODO: we should typecheck the codeblock again with the merged stack.
    if !@stack.compat_branches?(start_stack)
      raise "#{wok_loop.pos}: loop starts with #{start_stack}, ends with #{@stack}"
    end
    @loop_end_labels.pop
    @stack = @loop_end_stacks.pop
  end

  def emit_break(pos)
    if @loop_end_labels.empty?
      raise "#{pos}: break outside of loop"
    end
    end_stack = @loop_end_stacks.pop

    if end_stack.stopped?
      @loop_end_stacks << @stack.dup
    else
      if !end_stack.compat_branches?(@stack)
        raise "#{pos}: 'break' with stack #{@stack} instead of previous #{end_stack}"
      end
      end_stack.merge(@stack)
      @loop_end_stacks << end_stack
      @stack.stop!
    end
    
    emit('wok_break ' + @loop_end_labels.last)
  end

  def emit_push_int(int)
    @stack.push_int()
    if int.i == 0
      emit('wok_const_0')
    else
      emit('wok_const_int ' + int.i.to_s)
    end
  end

  def emit_push_str(str)
    @stack.push_str()
    emit("wok_const_str #{str2asm(str.text)}")
  end

  def perform_cast(cast)
    @stack.apply(cast.effect, cast.pos)
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

  def verify_type(type)
    case type
    when WokAdr, WokPtr
      verify_type(type.type)
    when WokTypeName
      found = @types.lookup(type.name)
      if !found
        raise "#{type.pos}: unknown type: #{type.name}"
      end
    end
  end

  def verify_effect_types(effect)
    effect.from.each { |t| verify_type(t) }
    effect.to.each { |t| verify_type(t) }
  end

  def str2asm(str)
    result = ''
    in_quotes = false
    start = true
    str.each_byte do |b|
      if b >= 32 && b <= 126
        if !in_quotes
          if !start
            result += ','
          else
            start = false
          end
          result += '"'
          in_quotes = true
        end
        result += b.chr
      else
        if in_quotes
          result += '"'
          in_quotes = false
        end
        if start
          start = false
        else
          result += ','
        end
        result += b.to_s
      end
    end
    if in_quotes
      result += '"'
    end
    if !start
      result += ','
    end
    result += '0'
    result
  end

end

class WokModule
  def initialize
    @content = {}
  end

  def lookup(name) # may return nil!
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

class Types
  def initialize
    @content = {}
  end

  def lookup(name) # may return nil!
    @content[name]
  end

  def register(name, value)
    old = lookup(name)
    if old != nil
      raise "#{value.pos}: #{name} previously defined at #{old.pos}"
    end
    @content[name] = value
  end

end

class TypeDef
  def initialize(name, pos, old)
    @name = name
    @pos = pos
    @old = old
  end

  def name
    @name
  end

  def pos
    @pos
  end

  def old
    @old
  end
end

class PrimitiveType
  def initialize(name, pos, size, signed)
    @name = name
    @pos = pos
    @size = size
    @signed = signed
  end

  def name
    @name
  end

  def pos
    @pos
  end

  def size
    @size
  end

  def signed
    @signed
  end
end

class WokStack
  def initialize(stack, types)
    @stack = stack
    @types = types
    @type_int = WokTypeName.new('int', '(builtin)')
    @type_bool = WokTypeName.new('bool', '(builtin)')
    @type_str = WokAdr.new(WokTypeName.new('u8', '(builtin)'))
    @stopped = false
  end

  def dup
    res = WokStack.new(@stack.dup, @types)
    res.stop! if @stopped
    res
  end

  def stop!
    @stopped = true
    @stack = []
  end

  def stopped?
    @stopped
  end

  def stack
    @stack
  end

  def to_s
    '[' + @stack.map { |t| t.to_s }.join(' ') + ']'
  end

  def push(type)
    if !pushable?(type)
      raise "#{'TODO'}: can not push a #{type} on the stack directly"
    end
    if typename?(type)
      case type.name
      when 's32', 's16', 's8', 'u32', 'u16', 'u8'
        push_int()
      else
        @stack.push(type)
      end
    else
      @stack.push(type)
    end
  end

  def push_int()
    push(@type_int)
  end

  def push_bool()
    push(@type_bool)
  end

  def push_str()
    push(@type_str)
  end

  def at(pos)
    tos = pop(pos)
    if !adr?(tos)
      raise "#{pos}: @-dereferencing a #{tos}"
    end
    if !pushable?(tos.type)
      raise "#{pos}: can not @-dereference and push a #{type} directly"
    end
    return tos.type
  end

  def bang(pos)
    tos = pop(pos)
    nos = pop(pos)
    if any?(tos)
      target = tos
      result = tos
    else
      if !tos.is_a?(WokAdr)
        raise "#{pos}: attempting to set a #{tos}, should be an @address"
      end
      target = tos.type
      result = tos.type
      if target.is_a?(WokTypeName)
        target = case target.name
                 when 'u8', 'u16', 'u32', 's8', 's16', 's32'
                   WokTypeName.new('int', '(builtin)')
                 else
                   target
                 end
      end
    end
    if !same_type?(nos, target)
      raise "#{pos}: attempting to set a #{tos} with a value of type #{nos}"
    end
    result
  end

  def this(pos)
    tos = pop(pos)
    push(tos)
    push(tos)
  end

  def that(pos)
    tos = pop(pos)
    nos = pop(pos)
    push(nos)
    push(tos)
    push(nos)
  end

  def alt(pos)
    tos = pop(pos)
    nos = pop(pos)
    push(tos)
    push(nos)
  end

  def nip(pos)
    tos = pop(pos)
    nos = pop(pos)
    push(tos)
  end

  def tuck(pos)
    tos = pop(pos)
    nos = pop(pos)
    push(tos)
    push(nos)
    push(tos)
  end

  def them(pos)
    tos = pop(pos)
    nos = pop(pos)
    push(nos)
    push(tos)
    push(nos)
    push(tos)
  end

  def dropem(pos)
    tos = pop(pos)
    nos = pop(pos)
  end

  def wok_and(pos)
    tos = pop_intbool(pos)
    nos = pop_intbool(pos)
    if !same_type?(tos, nos)
      raise "#{pos}: args of different types: #{tos} and #{nos}"
    end
    push(any?(tos) ? nos : tos, pos)
  end

  def wok_or(pos)
    wok_and(pos)
  end

  def wok_not(pos)
    tos = pop_intbool(pos)
    push(tos)
  end

  def mod(pos)
    pop_int(pos)
    pop_int(pos)
    push_int()
  end

  def drop(pos)
    tos = pop(pos)
  end

  def mod(pos)
    pop_int(pos)
    pop_int(pos)
    push_int()
  end

  def plus(pos)
    mod(pos)
  end

  def minus(pos)
    mod(pos)
  end

  def mul(pos)
    mod(pos)
  end

  def div(pos)
    mod(pos)
  end

  def is_eq(pos)
    tos = pop(pos)
    nos = pop(pos)
    if !same_type?(tos, nos)
      raise "#{pos}: args of different types: #{tos} and #{nos}"
    end
    push_bool()
  end

  def is_ne(pos)
    is_eq(pos)
  end

  def is_gt(pos)
    pop_int(pos)
    pop_int(pos)
    push_bool()
  end

  def is_lt(pos)
    is_gt(pos)
  end

  def is_ge(pos)
    is_gt(pos)
  end

  def is_le(pos)
    is_gt(pos)
  end

  def eq0(pos)
    pop_int(pos)
    push_bool()
  end

  def ne0(pos)
    eq0(pos)
  end

  def shift_left(pos)
    mod(pos)
  end

  def ashift_right(pos)
    mod(pos)
  end

  def lshift_right(pos)
    mod(pos)
  end

  # TODO: self, idx

  def apply(effect, pos)
    effect.from.reverse.each do |type|
      tos = pop(pos)
      if !can_use?(tos, as: type)
        raise "#{pos}: expected #{type} value on stack, but had #{tos} value"
      end
    end

    effect.to.each do |type|
      push(type)
    end
  end

  def can_use_stack?(as:)
    if @stack.size != as.size
      return false
    end
    i = 0
    loop do
      break if i == @stack.size
      if !can_use?(@stack[i], as: as[i])
        return false
      end
      i += 1
    end
    true
  end

  def pop_bool(pos)
    t = pop(pos)
    if !same_type?(t, @type_bool)
      raise "#{pos}: expected bool, got #{t}"
    end
  end

  def compat_branches?(stack2)
    if @stopped || stack2.stopped?
      return true
    end
    if @stack.size != stack2.stack.size
      return false
    end
    i = 0
    loop do
      break if i == @stack.size
      if !same_type?(@stack[i], stack2.stack[i])
        return false
      end
      i += 1
    end
    return true
  end

  def merge(stack2)
    return if stack2.stopped?

    if @stopped
      @stopped = false
      @stack = stack2.stack
      return
    end

    i = 0
    loop do
      break if i == @stack.size
      @stack[i] = type_merge(@stack[i], stack2.stack[i])
      i += 1
    end
  end

  def pop(pos)
    if @stack.empty?
      raise "#{pos}: expected value on stack, but it was empty"
    end
    @stack.pop()
  end

  private

  def type_merge(t1, t2)
    if typename?(t1) && typename?(t2) && t1.name == t2.name
      return t1
    end
    if any?(t1)
      return t2
    end
    if any?(t2)
      return t1
    end
    if (adr?(t1) && adr?(t2)) ||
       (adr?(t1) && ptr?(t2)) ||
       (ptr?(t1) && adr?(t2))
      return WokAdr.new(type_merge(t1.type, t2.type))
    end
    if ptr?(t1) && ptr?(t2)
      return WokPtr.new(type_merge(t1.type, t2.type))
    end
    raise "#{'TODO'}: incompatible types #{t1} and #{t2}"
  end

  def pop_int(pos)
    t = pop(pos)
    if !same_type?(t, @type_int)
      raise "#{pos}: expected int, got #{t}"
    end
  end

  def pop_intbool(pos)
    t = pop(pos)
    if !same_type?(t, @type_int) &&
       !same_type?(t, @type_bool)
      raise "#{pos}: expected int or bool, got #{t}"
    end
    t
  end

  def pushable?(t)
    !(typename?(t) && compound?(@types.lookup(t)))
  end

  def compound?(t)
    t.is_a?(WokClass) || (t.is_a?(WokOpt) && !t.primitive_opt?)
  end

  def can_use?(type, as:)
    if same_type?(type, as)
      return true
    end
    if type.is_a?(WokAdr) && as.is_a?(WokPtr)
      return can_use?(type.type, as: as.type)
    end
    return false
  end

  def same_type?(t1, t2)
    if any?(t1) || any?(t2)
      return true
    end
    if typename?(t1) && typename?(t2) && t1.name == t2.name
      return true
    end
    if adr?(t1) && adr?(t2) && same_type?(t1.type, t2.type)
      return true
    end
    if ptr?(t1) && ptr?(t2) && same_type?(t1.type, t2.type)
      return true
    end
    return false
  end

  def typename?(t)
    t.is_a?(WokTypeName) 
  end
  def any?(t)
    typename?(t) && t.name == 'any'
  end
  def adr?(t)
    t.is_a?(WokAdr) 
  end
  def ptr?(t)
    t.is_a?(WokPtr) 
  end
end

class OpCast
  def initialize(effect, pos)
    @effect = effect
    @pos = pos
    if effect.from.size != effect.to.size
      raise "#{pos}: type cast may not alter number of elements on stack"
    end
  end

  def effect
    @effect
  end

  def pos
    @pos
  end
end

class WokClass
  # TODO
end

class WokOpt

  # whether it's a single value, i.e. can be put on the stack
  def primitive_opt?
    false # TODO
  end
end

com = Compiler.new(ARGV[0])
com.compile()

