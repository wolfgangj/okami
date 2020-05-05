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

  def peek
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
