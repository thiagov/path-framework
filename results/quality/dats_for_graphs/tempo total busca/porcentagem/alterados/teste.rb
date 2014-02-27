
Dir.foreach('.') do |infile|
  next if infile == '.' or infile == '..' or infile.split(".")[1] != "dat"

  min = 1.0/0.0
  File.open("#{infile}", "r") do |i_file|
    line = i_file.gets
    while line = i_file.gets
      x = line.split(" ")
      x.shift
      x = x.map{|el| el.to_f}
      local_min = x.min
      if local_min < min
        min = local_min
      end
    end
  end

  File.open("#{infile}", "r") do |i_file|
    File.open("porcentagem/#{infile}", "w") do |o_file|
      line = i_file.gets
      o_file.puts(line)
      while line = i_file.gets
        x = line.split(" ")
        name = x.shift
        x = x.map{|el| (((el.to_f - min)/min.to_f)*100) + 100}
        o_file.puts "#{name} #{x.join(" ")}"
      end
    end
  end
end
