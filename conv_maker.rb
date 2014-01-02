#encoding: utf-8
require "pp"
require "pony"

#TODO: Teste de convergencia. Deve ser feito para:
# d_lite  - Não aplicável?
# lrta    - OK
# prta    - Não aplicável
# lsslrta - OK
# rtaa    - OK
# tbaa    - OK
# lrta_k  - OK
# plrta   - OK
# tba     - Não aplicável?

maps = ["arena.map", "den101d.map"]

conditions = [
#  {:algorithm => "d_lite",  :lookaheads => [[1, 0]]}, #OK!
#  {:algorithm => "prta",    :lookaheads => [[1, 0]]}, #OK!
#  {:algorithm => "tba",     :lookaheads => [[230, 0], [450, 0], [800, 0], [1100, 0]} #OK!
  {:algorithm => "lrta",    :lookaheads => [[1, 0]]}, #OK!
  {:algorithm => "lsslrta", :lookaheads => [[90, 0], [150, 0], [230, 0], [310, 0]]}, #OK!
  {:algorithm => "rtaa",    :lookaheads => [[180, 0], [450, 0], [800, 0], [1100, 0]]}, #OK
  {:algorithm => "tbaa",    :lookaheads => [[180, 0], [420, 0], [660, 0], [880, 0]]}, #OK!
  {:algorithm => "lrta_k",  :lookaheads => [[10000, 0]]}, #OK!
  {:algorithm => "plrta",   :lookaheads => [[140, 100], [270, 100], [480, 100], [700, 100]]} #OK!
]

begin
  conditions.each do |condition|
    algorithm  = condition[:algorithm]
    lookaheads = condition[:lookaheads]
    lookaheads.each do |lookahead_tuple|
      lookahead  = lookahead_tuple[0]
      queue_size = lookahead_tuple[1]
      maps.each do |sf|
        File.open("results/used/#{algorithm}___#{sf.split(".")[0]}___look-#{lookahead}.csv", "w") do |outfile|
          File.open("maps/used/#{sf}.scen", "r") do |infile|
            version = infile.gets

            cnt = 0
            header = "Teste,Bucket,Num. Solves,Total Time,Final Cost"
            outfile.puts(header)
            while line = infile.gets
              line = line.delete("\n")
              bucket, map, width, height, sx, sy, gx, gy, optimal = line.split(/\s/)
              sx = sx.to_i
              sy = sy.to_i
              gx = gx.to_i
              gy = gy.to_i
              optimal = optimal.to_f

              result = %x[ruby convergence.rb #{sy} #{sx} #{gy} #{gx} #{sf} #{algorithm} #{lookahead} #{queue_size}]
              total_solves, total_time, final_cost = result.split("\n")

              total_solves = total_solves.split(": ")[1].to_f
              total_time   = total_time.split(": ")[1].to_f
              final_cost   = final_cost.split(": ")[1].to_f


              cnt += 1
              outfile.puts("#{cnt},#{bucket},#{total_solves},#{total_time},#{final_cost}")
            end
          end
        end
        pp "Finalizado mapa #{sf} para #{algorithm} com lookaheads #{lookahead_tuple}"
      end
    end
  end

  Pony.mail({
    :to => 'thiagosilvavilela@gmail.com',
    :subject => 'Teste convergencia terminado',
    :body => 'Acabaram os testes :)',
    :via => :smtp,
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => 'thiago@superficie.org',
      :password             => 'sulamerica',
      :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
    }
  })

rescue => error
  Pony.mail({
    :to => 'thiagosilvavilela@gmail.com',
    :subject => 'Erro no script de convergencia',
    :body => 'Ocorreu um erro :(',
    :via => :smtp,
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => 'thiago@superficie.org',
      :password             => 'sulamerica',
      :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
    }
  })

  puts "="*20
  puts error
  puts "="*20
  puts error.backtrace
  puts "="*20
end
