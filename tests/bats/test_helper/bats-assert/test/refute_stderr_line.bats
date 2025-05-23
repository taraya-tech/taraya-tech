#!/usr/bin/env bats

load test_helper

setup_file() {
  bats_require_minimum_version 1.5.0
}

echo_err() {
  echo "$@" >&2
}

printf_err() {
  # shellcheck disable=2059
  printf "$@" >&2
}

###############################################################################
# Containing a line
###############################################################################

#
# Literal matching
#

# Correctness
@test "refute_stderr_line() <unexpected>: returns 0 if <unexpected> is not a line in \`\${stderr_lines[@]}'" {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line 'd'
  assert_test_pass
}

@test "refute_stderr_line() <unexpected>: returns 1 and displays details if <unexpected> is not a line in \`\${stderr_lines[@]}'" {
  run --separate-stderr echo_err 'a'
  run refute_stderr_line 'a'

  assert_test_fail <<'ERR_MSG'

-- line should not be in stderr --
line   : a
index  : 0
stderr : a
--
ERR_MSG
}

# Output formatting
@test "refute_stderr_line() <unexpected>: displays \`\$stderr' in multi-line format if it is longer than one line" {
  run --separate-stderr printf_err 'a 0\na 1\na 2'
  run refute_stderr_line 'a 1'

  assert_test_fail <<'ERR_MSG'

-- line should not be in stderr --
line  : a 1
index : 1
stderr (3 lines):
  a 0
> a 1
  a 2
--
ERR_MSG
}

# Options
@test 'refute_stderr_line() <unexpected>: performs literal matching by default' {
  run --separate-stderr echo_err 'a'
  run refute_stderr_line '*'
  assert_test_pass
}


#
# Partial matching: `-p' and `--partial'
#

# Options
@test 'refute_stderr_line() -p <partial>: enables partial matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line -p 'd'
  assert_test_pass
}

@test 'refute_stderr_line() --partial <partial>: enables partial matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --partial 'd'
  assert_test_pass
}

# Correctness
@test "refute_stderr_line() --partial <partial>: returns 0 if <partial> is not a substring in any line in \`\${stderr_lines[@]}'" {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --partial 'd'
  assert_test_pass
}

@test "refute_stderr_line() --partial <partial>: returns 1 and displays details if <partial> is a substring in any line in \`\${stderr_lines[@]}'" {
  run --separate-stderr echo_err 'a'
  run refute_stderr_line --partial 'a'

  assert_test_fail <<'ERR_MSG'

-- no line should contain substring --
substring : a
index     : 0
stderr    : a
--
ERR_MSG
}

# Output formatting
@test "refute_stderr_line() --partial <partial>: displays \`\$stderr' in multi-line format if it is longer than one line" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --partial 'b'

  assert_test_fail <<'ERR_MSG'

-- no line should contain substring --
substring : b
index     : 1
stderr (3 lines):
  a
> abc
  c
--
ERR_MSG
}


#
# Regular expression matching: `-e' and `--regexp'
#

# Options
@test 'refute_stderr_line() -e <regexp>: enables regular expression matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line -e '^.d'
  assert_test_pass
}

@test 'refute_stderr_line() --regexp <regexp>: enables regular expression matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --regexp '^.d'
  assert_test_pass
}

# Correctness
@test "refute_stderr_line() --regexp <regexp>: returns 0 if <regexp> does not match any line in \`\${stderr_lines[@]}'" {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --regexp '.*d.*'
  assert_test_pass
}

@test "refute_stderr_line() --regexp <regexp>: returns 1 and displays details if <regexp> matches any lines in \`\${stderr_lines[@]}'" {
  run --separate-stderr echo_err 'a'
  run refute_stderr_line --regexp '.*a.*'

  assert_test_fail <<'ERR_MSG'

-- no line should match the regular expression --
regexp : .*a.*
index  : 0
stderr : a
--
ERR_MSG
}

# Output formatting
@test "refute_stderr_line() --regexp <regexp>: displays \`\$stderr' in multi-line format if longer than one line" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --regexp '.*b.*'

  assert_test_fail <<'ERR_MSG'

-- no line should match the regular expression --
regexp : .*b.*
index  : 1
stderr (3 lines):
  a
> abc
  c
--
ERR_MSG
}


###############################################################################
# Matching single line: `-n' and `--index'
###############################################################################

# Options
@test 'refute_stderr_line() -n <idx> <expected>: matches against the <idx>-th line only' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line -n 1 'd'
  assert_test_pass
}

@test 'refute_stderr_line() --index <idx> <expected>: matches against the <idx>-th line only' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 'd'
  assert_test_pass
}

@test 'refute_stderr_line() --index <idx>: returns 1 and displays an error message if <idx> is not an integer' {
  run refute_stderr_line --index 1a

  assert_test_fail <<'ERR_MSG'

-- ERROR: refute_stderr_line --
`--index' requires an integer argument: `1a'
--
ERR_MSG
}


#
# Literal matching
#

# Correctness
@test "refute_stderr_line() --index <idx> <unexpected>: returns 0 if <unexpected> does not equal \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 'd'
  assert_test_pass
}

@test "refute_stderr_line() --index <idx> <unexpected>: returns 1 and displays details if <unexpected> equals \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 'b'

  assert_test_fail <<'ERR_MSG'

-- line should differ --
index : 1
line  : b
--
ERR_MSG
}

# Options
@test 'refute_stderr_line() --index <idx> <unexpected>: performs literal matching by default' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 '*'
  assert_test_pass
}


#
# Partial matching: `-p' and `--partial'
#

# Options
@test 'refute_stderr_line() --index <idx> -p <partial>: enables partial matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 -p 'd'
  assert_test_pass
}

@test 'refute_stderr_line() --index <idx> --partial <partial>: enables partial matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 --partial 'd'
  assert_test_pass
}

# Correctness
@test "refute_stderr_line() --index <idx> --partial <partial>: returns 0 if <partial> is not a substring in \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --index 1 --partial 'd'
  assert_test_pass
}

@test "refute_stderr_line() --index <idx> --partial <partial>: returns 1 and displays details if <partial> is a substring in \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --index 1 --partial 'b'

  assert_test_fail <<'ERR_MSG'

-- line should not contain substring --
index     : 1
substring : b
line      : abc
--
ERR_MSG
}


#
# Regular expression matching: `-e' and `--regexp'
#

# Options
@test 'refute_stderr_line() --index <idx> -e <regexp>: enables regular expression matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 -e '[^.b]'
  assert_test_pass
}

@test 'refute_stderr_line() --index <idx> --regexp <regexp>: enables regular expression matching' {
  run --separate-stderr printf_err 'a\nb\nc'
  run refute_stderr_line --index 1 --regexp '^.b'
  assert_test_pass
}

# Correctness
@test "refute_stderr_line() --index <idx> --regexp <regexp>: returns 0 if <regexp> does not match \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --index 1 --regexp '.*d.*'
  assert_test_pass
}

@test "refute_stderr_line() --index <idx> --regexp <regexp>: returns 1 and displays details if <regexp> matches \`\${stderr_lines[<idx>]}'" {
  run --separate-stderr printf_err 'a\nabc\nc'
  run refute_stderr_line --index 1 --regexp '.*b.*'

  assert_test_fail <<'ERR_MSG'

-- regular expression should not match line --
index  : 1
regexp : .*b.*
line   : abc
--
ERR_MSG
}


###############################################################################
# Common
###############################################################################

@test "refute_stderr_line(): \`--partial' and \`--regexp' are mutually exclusive" {
  run refute_stderr_line --partial --regexp

  assert_test_fail <<'ERR_MSG'

-- ERROR: refute_stderr_line --
`--partial' and `--regexp' are mutually exclusive
--
ERR_MSG
}

@test 'refute_stderr_line() --regexp <regexp>: returns 1 and displays an error message if <regexp> is not a valid extended regular expression' {
  run refute_stderr_line --regexp '[.*'

  assert_test_fail <<'ERR_MSG'

-- ERROR: refute_stderr_line --
Invalid extended regular expression: `[.*'
--
ERR_MSG
}

@test "refute_stderr_line(): \`--' stops parsing options" {
  run --separate-stderr printf_err 'a\n--\nc'
  run refute_stderr_line -- '-p'
  assert_test_pass
}
