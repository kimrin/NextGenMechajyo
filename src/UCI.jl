const StartFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"::ASCIIString

type Option
    defaultValue::String
    currentValue::String
    otype::String
    min::Int64
    max::Int64
    idx::Uint64 # I haven't seen where idx used
    on_change::Function
    uci::UCI
    usi::USI
    
    NOuci = UCI() # with garbage
    NOusi = USI() # with garbage

    # USI C'tors
    function Option(v::Int64, minv::Int64, maxv::Int64, u::USI, on_c::Function = on_callback_do_nothing)
        new( "$v", "$v", "spin", minv, maxv, uint64(0xdead), on_c, NOuci, u)
    end
    function Option(v::String, u::USI, on_c::Function = on_callback_do_nothing)
        new( v, v, "string", int64(0), int64(0), uint64(0xdead), on_c, NOuci, u)
    end
    function Option(u::USI, on_c::Function = on_callback_do_nothing)
        new( "", "", "button", int64(0), int64(0), uint64(0xdead), on_c, NOuci, u)
    end
    function Option(v::Bool, u::USI, on_c::Function = on_callback_do_nothing)
        de::String = v ? "true": "false"
        new( de, de, "check", int64(0), int64(0), uint64(0xdead), on_c, NOuci, u)
    end

    # UCI C'tors
    function Option(v::Int64, minv::Int64, maxv::Int64, u::UCI, on_c::Function = on_callback_do_nothing)
        new( "$v", "$v", "spin", minv, maxv, uint64(0xdead), on_c, u, NOusi)
    end
    function Option(v::String, u::UCI, on_c::Function = on_callback_do_nothing)
        new( v, v, "string", int64(0), int64(0), uint64(0xdead), on_c, u, NOusi)
    end
    function Option(u::UCI, on_c::Function = on_callback_do_nothing)
        new( "", "", "button", int64(0), int64(0), uint64(0xdead), on_c, u, NOusi)
    end
    function Option(v::Bool, u::UCI, on_c::Function = on_callback_do_nothing)
        de::String = v ? "true": "false"
        new( de, de, "check", int64(0), int64(0), uint64(0xdead), on_c, u, NOusi)
    end
end

typealias OptionMap Dict{String,Option}

function int(o::Option)
    if o.otype == "check" || o.otype == "spin"
        return (o.otype == "spin") ? Int64(o.currentValue): (o.currentValue == "true")
    end
    return -1 # not happen!
end
function string(o::Option)
    if o.otype == "string"
        return o.currentValue
    end
    return "no string" # not happen!
end

function on_logger(opt::Option)
    println("start logger")
end

function on_eval(opt::Option)
    println("Eval::init()")
end

function on_threads(opt::Option)
    println("Threads.read_uci_options()")
end

function on_hash_size(opt::Option)
    println("TT.resize(o)")
end

function on_clear_hash(opt::Option)
    println("TT.clear()")
end

function on_callback_do_nothing(opt::Option)
    println("dummy callback is called($opt)")
end

function initialize(uci::UCI)
    uci.is_callback_enable = false

    o = OptionMap()
    
    o["Write Debug Log"]             = Option(false, uci, on_logger)
    o["Write Search Log"]            = Option(false, uci)
    o["Search Log Filename"]         = Option("SearchLog.txt", uci)
    o["Book File"]                   = Option("book.bin", uci)
    o["Best Book Move"]              = Option(false, uci)
    o["Contempt Factor"]             = Option(0, -50, 50, uci)
    o["Mobility (Midgame)"]          = Option(100, 0, 200, uci, on_eval)
    o["Mobility (Endgame)"]          = Option(100, 0, 200, uci, on_eval)
    o["Pawn Structure (Midgame)"]    = Option(100, 0, 200, uci, on_eval)
    o["Pawn Structure (Endgame)"]    = Option(100, 0, 200, uci, on_eval)
    o["Passed Pawns (Midgame)"]      = Option(100, 0, 200, uci, on_eval)
    o["Passed Pawns (Endgame)"]      = Option(100, 0, 200, uci, on_eval)
    o["Space"]                       = Option(100, 0, 200, uci, on_eval)
    o["Aggressiveness"]              = Option(100, 0, 200, uci, on_eval)
    o["Cowardice"]                   = Option(100, 0, 200, uci, on_eval)
    o["Min Split Depth"]             = Option(0, 0, 12, uci, on_threads)
    o["Max Threads per Split Point"] = Option(5, 4,  8, uci, on_threads)
    o["Threads"]                     = Option(1, 1, MAX_THREADS, uci, on_threads)
    o["Idle Threads Sleep"]          = Option(true, uci)
    o["Hash"]                        = Option(32, 1, 16384, uci, on_hash_size)
    o["Clear Hash"]                  = Option(uci, on_clear_hash)
    o["Ponder"]                      = Option(true, uci)
    o["OwnBook"]                     = Option(false, uci)
    o["MultiPV"]                     = Option(1, 1, 500, uci)
    o["Skill Level"]                 = Option(20, 0, 20, uci)
    o["Emergency Move Horizon"]      = Option(40, 0, 50, uci)
    o["Emergency Base Time"]         = Option(60, 0, 30000, uci)
    o["Emergency Move Time"]         = Option(30, 0, 5000, uci)
    o["Minimum Thinking Time"]       = Option(20, 0, 5000, uci)
    o["Slow Mover"]                  = Option(80, 10, 1000, uci)
    o["UCI_Chess960"]                = Option(false, uci)
    o["UCI_AnalyseMode"]             = Option(false, uci, on_eval)

    uci.is_callback_enable = true
    
    return o
end

function setindex!(omap::OptionMap, value::Option, key::String)
    if value.uci.is_callback_enable
        value.on_change(value)
    end
end

#Chess Server
function producer(uci::UCI, omap::OptionMap, host::ASCIIString, port::Int)
    err = 0
    server = listen(getaddrinfo(host), int(port))
    println(server)
    while true
        conn = accept(server)
        println(conn)
        @async begin
            try
                while true
                    println("before readline")
                    line = readline(conn)
                    print("in server loop:", line)
                    chomp(line)
                    println(conn, "REPLY:", line)
                    lis = line #[line,conn]
                    produce(lis)
                end
            catch err
                print("connection ended with error $err")
            end
        end
    end
    return err
end

function mainLoop(uci::UCI, omap::OptionMap, host::ASCIIString, port::Int)
    p = @task producer(uci, omap, host, port)
    while true
        println("before consume")
        li = consume(p)
        line = li
        #sock = li[2]
        println("line,sock=", line, sock)

        comlist = split(line)

        token = comlist[1]

        println("task:",line)

        if token == "quit" || token == "stop" || token == "ponderhit"
            # The GUI sends 'ponderhit' to tell us to ponder on the same move the
            # opponent has played. In case Signals.stopOnPonderhit is set we are
            # waiting for 'ponderhit' to stop the search (for instance because we
            # already ran out of time), otherwise we should continue searching but
            # switch from pondering to normal search.
            if token != "ponderhit" || false #Search::Signals.stopOnPonderhit
                # Search::Signals.stop = true;
                # Threads.main()->notify_one(); // Could be sleeping
                return 0
            else
                # Search::Limits.ponder = false;
            end

        elseif token == "perft"
            pos = ""
            blist = [Options["Hash"],Options["Threads"], int(comlist[2]), "current", "perft"]
            benchmark(pos, blist)
        elseif token == "key"
            #sync_cout << hex << uppercase << setfill('0')
            #        << "position key: "   << setw(16) << pos.key()
            #        << "\nmaterial key: " << setw(16) << pos.material_key()
            #        << "\npawn key:     " << setw(16) << pos.pawn_key()
            #        << dec << sync_endl;
        elseif token == "uci"
            println( sock, engine_info(true, Chess))
            for k in keys(oMap)
                v = oMap[k]

                ostr = "option name $(k) type $(v.otype) "
                if v.otype != "button"
                    ostr *= "default " * v.defaultValue
                end
                if v.otype == "spin"
                    ostr *= "min " * v.min * " max " * v.max
                end
                println(sock, ostr)
            end
            # sync_cout << "id name " << engine_info(true)
            #    << "\n"       << Options
            # << "\nuciok"  << sync_endl;
            println("uciok")
        # elseif token == "eval"
        #     # Search::RootColor = pos.side_to_move(); // Ensure it is set
        #     # sync_cout << Eval::trace(pos) << sync_endl;
        # elseif token == "ucinewgame"
        #     # TT.clear();
        # elseif token == "go"
        #     # go(pos, is);
        # elseif token == "position"
        #     # position(pos, is);
        # elseif token == "setoption"
        #     # setoption(is);
        # elseif token == "flip"
        #     # pos.flip();
        # elseif token == "bench"
        #     # benchmark(pos, is);
        # elseif token == "d"
        #     # pos.pretty()
        # elseif token == "isready"
        #     println(sock, "readyok")
        else
          println("Unknown command: ", comlist)
        end
    end
end
