#encoding: utf-8
require "pp"

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

maps = ["hrt201n.map", "duskwood.map"]#"combat.map", "lak503d.map", "arena2.map", "duskwood.map"]

conditions = [
  {:algorithm => "d_lite",  :lookaheads => [[1, 0]]}, #OK!
  {:algorithm => "lrta",    :lookaheads => [[1, 0]]}, #OK!
  {:algorithm => "prta",    :lookaheads => [[1, 0]]}, #OK!
  {:algorithm => "lsslrta", :lookaheads => [[90, 0], [150, 0], [230, 0], [310, 0]]}, #OK!
  {:algorithm => "rtaa",    :lookaheads => [[180, 0], [450, 0], [800, 0], [1100, 0]]}, #OK
  {:algorithm => "tbaa",    :lookaheads => [[180, 0], [420, 0], [660, 0], [880, 0]]}, #OK!
  {:algorithm => "lrta_k",  :lookaheads => [[10000, 0]]}, #OK!
  {:algorithm => "plrta",   :lookaheads => [[140, 100], [270, 100], [480, 100], [700, 100]]} #OK!
#  {:algorithm => "tba",     :lookaheads => [[230, 0], [450, 0], [800, 0], [1100, 0]} #OK!
]

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
          header = "Teste,Bucket,Estados expandidos,Episódios de busca,Custo da trajetória,% Sol. Ótima,Ações por Episódio de Busca,Tempo Total Busca,Tempo Médio Episódio de Busca,Tempo Médio Busca por Ação,Tempo máximo de planejamento,Fifty,Ninety"
          outfile.puts(header)
          while line = infile.gets
            line = line.delete("\n")
            bucket, map, width, height, sx, sy, gx, gy, optimal = line.split(/\s/)
            sx = sx.to_i
            sy = sy.to_i
            gx = gx.to_i
            gy = gy.to_i
            optimal = optimal.to_f

            result = %x[ruby main.rb #{sy} #{sx} #{gy} #{gx} #{sf} #{algorithm} #{lookahead} #{queue_size}]
            expanded, episodes, cost, action_per_episode, total_time, episode_time, action_time, max_planning, fifty, ninety = result.split("\n")

            expanded           = expanded.split(": ")[1].to_f
            episodes           = episodes.split(": ")[1].to_i
            cost               = cost.split(": ")[1].to_f
            action_per_episode = action_per_episode.split(": ")[1].to_f
            total_time         = total_time.split(": ")[1].to_f
            episode_time       = episode_time.split(": ")[1].to_f
            action_time        = action_time.split(": ")[1].to_f
            max_planning       = max_planning.split(": ")[1].to_f
            fifty              = fifty.split(": ")[1].to_f
            ninety             = ninety.split(": ")[1].to_f

            cost_quality = (cost - optimal)/optimal
            cost_quality = 0.0 if cost_quality < 0.0

            path_size    = path_size.to_f
            path_quality = (path_size - optimal)/optimal

            cnt += 1
            outfile.puts("#{cnt},#{bucket},#{expanded},#{episodes},#{cost},#{cost_quality},#{action_per_episode},#{total_time},#{episode_time},#{action_time},#{max_planning},#{fifty},#{ninety}")
          end
        end
      end
      pp "Finalizado mapa #{sf} para #{algorithm} com lookaheads #{lookahead_tuple}"
    end
  end
end
