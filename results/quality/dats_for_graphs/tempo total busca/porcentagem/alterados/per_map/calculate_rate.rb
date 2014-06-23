require "pp"

file1 = ARGV[0]
file2 = ARGV[1]

algorithms = nil
data = []
File.open(file1, "r") do |infile|
  algorithms = infile.gets.split(" ")
  algorithms.shift
  if algorithms[0] == "\"D*"
    algorithms.shift
    algorithms[0] = "D* Lite"
  end
  algorithms.unshift(" ")
  data = []
  while map_data = infile.gets
    tmp = []
    tmp << map_data.match(/\"(.)*\"/)[0]
    map_data = map_data.gsub(/\"(.)*\"/, "")
    map_data = map_data.split(" ")
    map_data.each{|d| tmp << d}
    data << tmp
  end
#  pp data
end

algorithms2 = []
data2 = []
File.open(file2, "r") do |infile|
  algorithms2 = infile.gets.split(" ")
  algorithms2.shift
  if algorithms2[0] == "\"D*"
    algorithms2.shift
    algorithms2[0] = "D* Lite"
  end
  algorithms2.unshift(" ")
  data2 = []
  while map_data = infile.gets
    tmp = []
    tmp << map_data.match(/\"(.)*\"/)[0]
    map_data = map_data.gsub(/\"(.)*\"/, "")
    map_data = map_data.split(" ")
    map_data.each{|d| tmp << d}
    tmp.delete_at(-2) #deleta resultado do TBA*
    data2 << tmp
  end
#  pp data2
end

new_data = []

quant = 22
algorithms = algorithms.map{|a| a.rjust(quant)}
puts algorithms.join(" ")
data.size.times do |n|
  line = []
  data[n].size.times do |dn|
    if dn == 0
      line << data[n][dn].rjust(quant)
    else
      val1 = data[n][dn].to_f
      val2 = data2[n][dn].to_f
      val = (val1 - val2)/val1
      line << val.to_s.rjust(quant)
    end
  end
  puts line.join(" ")
end

# header = true
# while !algorithms.empty?
#   line = []
#   line << algorithms.shift
#   data.each do |arr|
#     if !header
#       num = arr.shift
#       num = num.to_f
#       num = (num + 1).round(3)
#       num = "%.3f" % num
#       num = num.to_s.gsub(".", ",")
#       line << num
#     else
#       line << arr.shift
#     end
#   end
#   line = line.join(" & ").gsub("\"", "")
#   line.concat(" \\\\")
#   puts line
#   if header
#     puts "\\hline"
#     header = false
#   end
# end
