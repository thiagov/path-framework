dir = ARGV[0]

Dir.foreach(dir) do |infile|
  next if infile == '.' or infile == '..' or infile.split(".")[1] != "csv"

  outfile = infile.gsub(".csv", ".dat")
  outfile = "buckets_#{outfile}"

  File.open("#{dir}/#{infile}", "r") do |i_file|
    File.open("#{dir}/dats/buckets/#{outfile}", "w") do |o_file|
      line = i_file.gets
      g_b = -1
      cnt = 0
      while line = i_file.gets
        n, b, num, time, cost = line.gsub("\n", "").split(",")

        if num.to_f != 0.0
          if b == g_b
            cnt    += 1
            g_num  += num.to_f
            g_time += time.to_f
            g_cost += cost.to_f
          else
            if g_b != -1
              o_file.puts("#{g_b} #{g_b} #{g_num.to_f/cnt.to_f} #{g_time.to_f/cnt.to_f}")
            end
            cnt    = 1
            g_b    = b
            g_num  = num.to_f
            g_time = time.to_f
            g_cost = cost.to_f
          end
        end
      end
    end
  end
end

