#----------------------------------------------------------------------------
# Capture the printed output so it can be examined (or ignored).
#----------------------------------------------------------------------------

# :reek:UtilityFunction
def capture_stdout
  old_stdout  = $stdout
  $stdout     = StringIO.new

  yield

  $stdout.string
ensure
  $stdout = old_stdout
end

#----------------------------------------------------------------------------
# Feed stdin with a prepared string
#----------------------------------------------------------------------------

# :reek:UtilityFunction
def feed_stdin(str)
  old_stdin  = $stdin
  $stdin     = StringIO.new str

  yield
ensure
  $stdin = old_stdin
end
