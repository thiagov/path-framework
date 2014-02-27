vis_arr = ["full-visibility", "visibility1", "visibility10"]

vis_arr.each do |vis|
  (1..4).each do |n|
    opt_dat  = "#{vis}-look#{n}-porcentagem_sol_otima.dat"
    time_dat = "#{vis}-look#{n}-tempo-total-busca.dat" 

    File.open("tradeoff/#{vis}-look#{n}-tradeoff.dat", 'w') do |out_file|
      File.open(opt_dat, 'r') do |opt_file|
        File.open(time_dat, 'r') do |time_file|
          h1 = opt_file.gets
          h2 = time_file.gets
          #puts h2
          out_file.puts(h2)
          while line1 = opt_file.gets && line2 = time_file.gets
            quality = line1.split(" ").map{|x| x.to_f == 0.0 ? x : x.to_f}
            time    = line2.split(" ").map{|x| x.to_f == 0.0 ? x : x.to_f}

            tradeoff = []
            tradeoff[0] = quality[0]
            quality.shift
            time.shift
            time.size.times do |x|
              tradeoff << quality[x] * time[x]
            end
            #puts tradeoff.join(" ")
            out_file.puts tradeoff.join(" ")
          end
        end
      end
    end
  end
end
