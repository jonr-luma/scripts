replacements = [
  { search: /Operation::.+\.call\((?!params:)/,             replace: "\\&params: " },
  { search: /(Operation::.+\.call\(.+)('current_user' =>)/, replace: "\\1current_user:" },
  { search: /((?<=Trailblazer::Operation))(.+)((step|fail|success|pass)\s:)(?<m>\w+)(.+)def\s\k<m>\W?\((?!_?options)/m, replace: "\\&_options, " },
  { search: /((?<=module Operation).+)(failure)(?=\s:\w+!?)/m, replace: "\\1fail" },
  { search: /((?<=module Operation).+)(success)(?=\s:\w+!?)/m, replace: "\\1pass" },
  { search: /(?<all>((?<=module Operation))(.+)((step|fail|success|pass)\s:)(?<m>\w+)(.+)def\s\k<m>\W?(?<paran>\((?>[^)(]|\g<paran>)*))(?<rparan>(?<!\*\*)\))/m, replace: "\\k<all>, **)" }
]

# Dir.glob will take care of the recursivity for you
# do not use ~ but rather Dir.home
rbfiles = File.join("#{Dir.home}/Github/luma_app/**", '*.rb')
Dir.glob(rbfiles) do |file_name|
  if File.file? file_name
    text = File.read(file_name)
    file_changes = false
    replacements.each do |replacement|
      s = replacement[:search]
      r = replacement[:replace]
      while replace = text.gsub!(s, r) do
        file_changes = true
        text = replace
      end
    end
    File.open(file_name, "w") { |file| file.puts text } if file_changes
  end
end
