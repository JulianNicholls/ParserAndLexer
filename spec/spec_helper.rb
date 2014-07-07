#----------------------------------------------------------------------------
# Capture the printed output so it can be examined (or ignored).
#----------------------------------------------------------------------------

def capture_stdout
  old_stdout  = $stdout
  fake_stdout = StringIO.new
  $stdout     = fake_stdout

  yield

  fake_stdout.string
ensure
  $stdout = old_stdout
end

#----------------------------------------------------------------------------
# Feed stdin with a prepared string
#----------------------------------------------------------------------------

def feed_stdin( str )
  old_stdin  = $stdin
  fake_stdin = StringIO.new str
  $stdin     = fake_stdin

  yield
ensure
  $stdin = old_stdin
end
