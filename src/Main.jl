# Next Generation メカ女子将棋 by メカ女子将棋部☆
# (License is under the GPLv3: see LICENSE file for more details)
# 
# メカ女子将棋部：
# 
# 竹部　さゆり（女流三段）様
#   メカさゆりん
# 渡辺　弥生（女流一段）様
#   メカみおたん
# 酒井　美由紀（洋裁顧問）様
# 　メカみゅーん
# 辻　理絵子（女子大学院生）様
#   メカりえぽん
# 木村　健（メカウーサーメカ担当、実装責任者）
#   メカきむりん、プロジェクトリーダー、小六女子w
# 
# (in English:)
#
# Next Generation Mecha Lady Shogi by Mecha Lady Shogi Team
# (License is under the GPLv3: see LICENSE file for more details)
#
# Mecha Lady Shogi Team Members:
# 
# Sayuri TAKEBE (Lady Shogi Prof. 3-Dan)
#  (Mecha Sayurin)
# Mio WATANABE  (Lady Shogi Prof. 1-Dan)
#  (Mecha Miotan)
# Miyuki SAKAI  (Master of Craftworker:)
#  (Mecha Myuun)
# Rieko TSUJI   (Master of Press Releases)
#  (Mecha Riepon)
# Takeshi KIMURA(Project leader, twitter:@kimrin)
#  (Mecha Kimrin)
#
# This Program is based on Stockfish Chess Program.
# So Structure of the code is based on its.
# 
# We ported portion of Stockfish codes from C++ to Julia.
# Then, we added playing ability of Shogi by using following features:
#
# * Shogi Move Generation routines (using BitBoard)
# * fv.bin based evaluation functions
#
#

using Mechajyo
using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--host"
            help = "host name"
            default = "localhost"
        "--magic"
            help = "calculate magic board multipliers and store data to files"
            default = "false"
        "port"
            help = "listen port number"
            required = true
    end

    return parse_args(s)
end

function main(game::Uint64, args)
    srand(73) # global random number seed

    parsed_args = parse_commandline()
    pdict = Dict{String,String}()

    for (arg,val) in parsed_args
        pdict[arg] = val
        # println("  $arg  =>  $val")
    end

    if game == Mechajyo.Chess
        univ = Mechajyo.UCI()
        println("Mechajyo Chess playing program")
    else # game == Shogi
        univ = Mechajyo.USI()
        println("Mechajyo Shogi playing program")
    end

    # output engine information (for debug)
    # print(Mechajyo.engine_info(true, game))

    # various initializations
    oMap = Mechajyo.initialize(univ)
    c = Mechajyo.Context(game)

    magic = pdict["magic"]
    #println("magic=",magic)
    mag = (magic == "false")?false:true
    println("calculate magics=",mag)

    if game == Mechajyo.Shogi
        bbb = c.sbb
        c.sbb.calcMagic = mag
    else
        bbb = c.bb
    end
    Mechajyo.initBB(bbb)

    println("establish server ($(pdict["host"])) port: ", pdict["port"])

    begin
        server = listen(getaddrinfo(pdict["host"]), int(pdict["port"]))
        while true
            println("waiting for connection...")
            sock = accept(server)
            println("establish connection!")
            while true
                ret = Mechajyo.mainLoop(univ, oMap, sock)
                if ret == "quit"
                    break
                end
            end
            close(sock)
        end
    end
end

