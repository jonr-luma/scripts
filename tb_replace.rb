replacements = [
  { search: /(?<call>Operation::.+\.call)(?<paran>(?<lparan>\()(?<inparam>(?!\s*params:)(?=\s*\W?\w+\W?\s*(:|=>))(?>[^)(]|\g<paran>)*)(?<rparan>\)))/, replace: "\\k<call>(params: { \\k<inparam> })" },
  { search: /Operation::.+\.call\((?!params:)/,             replace: "\\&params: " },
  { search: /(Operation::.+\.call\(.+)('current_user' =>)/, replace: "\\1current_user:" },
  { search: /((?<=Trailblazer::Operation))(.+)((step|fail|success|pass)\s:)(?<m>\w+)(.+)def\s\k<m>\W?\((?!_?options)/m, replace: "\\&_options, " },
  { search: /((?<=module Operation).+)(failure)(?=\s:\w+!?)/m, replace: "\\1fail" },
  { search: /((?<=module Operation).+)(success)(?=\s:\w+!?)/m, replace: "\\1pass" },
  { search: /(?<all>((?<=module Operation))(.+)((step|fail|success|pass)\s:)(?<m>\w+)(.+)def\s\k<m>\W?(?<paran>\((?>[^)(]|\g<paran>)*))(?<rparan>(?<!\*\*)\))/m, replace: "\\k<all>, **)" },
  { search: /(?<start>(?<=module\sOperation).+)(?<n>Nested\()/m, replace: "\\k<start>Subprocess(" },
  { search: /(?<start>Reform::Form.*type:\sTypes::(?=(Form)))(?<t>\w+::)/m, replace: "\\k<start>" },
  { search: /(?<start>Reform::Form.*type:\sTypes::(?!Params))(?<t>\w+)/m, replace: "\\k<start>Params::\\k<t>" },
  { search: /(?<start>Reform::Form.*type:\sTypes::(Params::)?)(?=Int)(?!Integer)(?<t>\w+)/m, replace: "\\k<start>Integer" }
]

puts "#======================================================#"
puts "# The Amazing Trailblazer 2.1 Migration Buddy!         #"
puts "#======================================================#"
# Dir.glob will take care of the recursivity for you
# do not use ~ but rather Dir.home
rbfiles = File.join("#{Dir.home}/Github/luma_app/**", '*.rb')
files_changed_count = 0
Dir.glob(rbfiles) do |file_name|
  if File.file? file_name
    text = File.read(file_name)
    file_changes = false
    changes_count = 0
    replacements.each do |replacement|
      s = replacement[:search]
      r = replacement[:replace]
      while replace = text.gsub!(s, r) do
        file_changes = true
        changes_count += 1
        text = replace
      end
    end
    if file_changes
      files_changed_count += 1
      puts "#{changes_count} changes in #{file_name}"
      File.open(file_name, "w") { |file| file.puts text }
    end
  end
end
puts "#======================================================#"
puts "# Run complete! Total files changed: #{files_changed_count} #"
puts "#======================================================#"
