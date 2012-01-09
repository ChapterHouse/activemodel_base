unless Object.const_defined?('NestedLogger')
require 'stringio'

class Object

  @@logDepth = 0
  @@log = true
  @@logIndent = "  "
  @@logInspectMethod = true
  @@loggerMethod = self.method(:puts)
  @@currentMethodForNestedLogging = nil

  def self.loggingOn
    @@log = true
  end

  def self.loggingOn?
    @@log == true
  end

  def self.loggingOff
    @@log = false
  end

  def self.loggingOff?
    @@log == false
  end

  def self.loggerMethod=(newValue)
    @@loggerMethod = newValue
  end

  def self.loggerMethod
    @@loggerMethod
  end

  def self.logDepth
    @@logDepth    
  end
  
  def self.logDepth=(newValue)
    @@logDepth = newValue
  end

  def self.logIndent
    @@logIndent
  end
  
  def self.logIndent=(newValue)
    @@logIndent = newValue
  end

  def self.logInspectMethod
    @@logInspectMethod    
  end
  
  def self.logInspectMethod=(newValue)
    @@logInspectMethod = newValue
  end

  def self.withLoggingOn(&block)
    old_value = loggingOn?
    loggingOn
    begin
      rc = yield
    rescue
      removeNestedLoggerFromBacktrace($!)
      raise
    ensure
      old_value ? loggingOn : loggingOff
    end
    rc
  end

  def self.withLoggingOff(&block)
    old_value = loggingOn?
    loggingOff
    begin
      rc = yield
    rescue
      removeNestedLoggerFromBacktrace($!)
      raise
    ensure
      old_value ? loggingOn : loggingOff
    end
    rc
  end
  
  def self.writelog(text)
    text.to_s.split("\n").each { |line| self.loggerMethod.call((logIndent * (logDepth >= 0 ? logDepth : 0)) + line) } if loggingOn?
  end
      
  def self.log(text)
    writelog text
    if block_given? then
      writelog "{"
      shouldBe = self.logDepth
      self.logDepth += 1
      begin
        @@logShowException = true
        rc = lambda(&Proc.new).call
      rescue => rc
        self.logDepth -= 1
        (self.logDepth - shouldBe).times {
          writelog "} return?"
          self.logDepth -= 1
        }
        writelog "}"
        if @@logShowException && loggingOn?
          removeNestedLoggerFromBacktrace($!)
          writelog ["*" * 15, rc.class.name, "*" * 15, rc.message, " "].join("\n")
          @@logShowException = false
        end
        raise
      else
        self.logDepth -= 1
        (self.logDepth - shouldBe).times {
          writelog "} return?"
          self.logDepth -= 1
        }
        writelog "} (#{rc.inspect})"
      end
      rc
    end
  end

  class << self
    alias :nlog :log
  end
 
  def self.log_method(*args)
    options = args.last.is_a?(Hash) && !args.last.empty? ? args.pop : {}
    text = currentMethodForNestedLogging + 
           "(" +
           (args.map(&:inspect) + 
           options.sort { |a, b| a.to_s <=> b.to_s }.map { |a, b| "#{a} = " + b.inspect }
           ).join(", ") +
           ")"
    block_given? ? self.log(text) { yield } : self.log(text)
  end

  def self.log_xml(xml, name=nil)
    begin
      pretty_xml = StringIO.new
      REXML::Document.new(xml).write(pretty_xml, 2)
      if name
        self.log(name) { self.log pretty_xml.string }
      else
        self.log pretty_xml.string
      end
    rescue
      if name
        log_variable name => xml
      else
        log_variable xml
      end
    end
    xml
  end
  
  def self.log_variables(*args)
    named_variables = args.last.is_a?(Hash) ? args.pop : {}
    (args.map(&:inspect) + named_variables.sort { |a, b| a.to_s <=> b.to_s }.map { |a, b| "#{a} = " + b.inspect } ).each { |text| self.log(text) }
  end

  def self.log_methods(object, filter=Object.new)
    label = (object.is_a?(Class) ? object.name : "Instance Of #{object.class.name}") + " methods"
    nlog(label) {
      methods = object.methods
      methods -= filter.methods if filter
      methods.map!(&:to_s)
      methods.sort!
      nlog methods.join("\n")
      label
    }
  end

  def self.log_stack(stack=nil)
    writelog nestedLoggerCleanStack(stack).join("\n")
  end
  
  def log(text)
    block_given? ? self.class.log(text) { yield } : self.class.log(text)
  end

  alias :nlog :log
  
  def log_method(*args)
    currentMethodForNestedLogging(true)
    block_given? ? self.class.log_method(*args) { yield } : self.class.log_method(*args)
  end

  def log_xml(xml, name=nil)
    self.class.log_xml(xml, name)
  end

  def log_variables(*args)
   self.class.log_variables(*args)
  end
  alias :log_variable :log_variables

  def log_methods(object, filter=Object.new)
    self.class.log_methods object, filter
  end

  def loggingOn
    self.class.loggingOn
  end

  def loggingOn?
    self.class.loggingOn?
  end

  def loggingOff
    self.class.loggingOff
  end

  def loggingOff?
    self.class.loggingOff?
  end

  def loggerMethod
    self.class.loggerMethod    
  end
  
  def loggerMethod=(newValue)
    self.class.loggerMethod = newValue
  end

  def logDepth
    self.class.logDepth    
  end
  
  def logDepth=(newValue)
    self.class.logDepth = newValue
  end

  def logIndent
    self.class.logIndent    
  end
  
  def logIndent=(newValue)
    self.class.logIndent = newValue
  end

  def logInspectMethod
    self.class.logInspectMethod    
  end
  
  def logInspectMethod=(newValue)
    self.class.logInspectMethod = newValue
  end

  def withLoggingOn(&block)
    self.class.withLoggingOn(&block)
  end

  def withLoggingOff(&block)
    self.class.withLoggingOff(&block)
  end

  def log_stack(stack=nil)
    self.class.log_stack(stack)
  end
  
  def log_errors(record)
    nlog record.errors.full_messages.join("\n")
  end

  private
  
  def currentMethodForNestedLogging(store=false)
    if @@currentMethodForNestedLogging
      rc = @@currentMethodForNestedLogging
    else
      stack_top = nestedLoggerCleanStack[0]
      m = stack_top.match(/.*`(.+?)'$/)
      unless m.nil?
        rc = logInspectMethod ? self.method(m[1].to_sym).inspect[10..-2] : m[1]
      else
        rc = stack_top.match(/.*\/(.+?)$/)[1]
      end
    end
    @@currentMethodForNestedLogging = store ? rc : nil
    rc
  end

  def nestedLoggerCleanStack(stack=nil)
#    (stack || caller).delete_if { |line| line.include?("NestedLogger")}
    (stack || caller).delete_if { |line| line.include?("nested_logger")}
  end

  def removeNestedLoggerFromBacktrace(exception)
    exception.set_backtrace(nestedLoggerCleanStack(exception.backtrace))
  end

end

class NestedLogger

  def self.<<(string)
    nlog string
    self
  end

  def self.write(string)
    nlog string
    self
  end

  def self.puts(string)
    nlog string
    self
  end

  def self.info(string)
    nlog "info: " + string
    self
  end

  def self.warn(string)
    nlog "warn: " + string
    self
  end

  def self.error(string)
    nlog "error: " + string
    self
  end

end

end


Object.loggerMethod = method(:puts) #Rails.logger.method(:info)
