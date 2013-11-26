dir = ARGV[0]

Dir.foreach(dir) do |infile|
  next if infile == '.' or infile == '..' or infile.split(".")[1] != "csv"

  outfile = infile.gsub(".csv", ".dat")
  File.open("#{dir}/#{infile}", "r") do |i_file|
    File.open("#{dir}/dats/#{outfile}", "w") do |o_file|
      while line = i_file.gets
        line = line.gsub(",", " ")
        o_file.write(line)
      end
    end
  end
end

