# Lint all Swift files
swiftlint.lint_files inline_mode: true

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if github.pr_title.include? "[WIP]"
    warn "PR is classed as Work in Progress"
end

# Warn when there is a big PR
if git.lines_of_code > 500
    warn "Big PR"
end

# Mainly to encourage writing up some reasoning about the PR, rather than just leaving a title
if github.pr_body.length == 0
  warn "Please provide a summary in the Pull Request description"
end
