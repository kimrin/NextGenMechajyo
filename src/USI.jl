const SFENHirate = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"::ASCIIString

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
    println("Threads.read_usi_options()")
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

function initialize(usi::USI)
    usi.is_callback_enable = false

    o = OptionMap()
    
    o["Write Debug Log"]             = Option(false, usi, on_logger)
    o["Write Search Log"]            = Option(false, usi)
    o["Search Log Filename"]         = Option("SearchLog.txt", usi)
    o["Book File"]                   = Option("book.bin", usi)
    o["Best Book Move"]              = Option(false, usi)
    o["Contempt Factor"]             = Option(0, -50, 50, usi)
    o["Min Split Depth"]             = Option(0, 0, 12, usi, on_threads)
    o["Max Threads per Split Point"] = Option(5, 4,  8, usi, on_threads)
    o["Threads"]                     = Option(1, 1, MAX_THREADS, usi, on_threads)
    o["Idle Threads Sleep"]          = Option(true, usi)
    o["Hash"]                        = Option(32, 1, 16384, usi, on_hash_size)
    o["Clear Hash"]                  = Option(usi, on_clear_hash)
    o["Ponder"]                      = Option(true, usi)
    o["OwnBook"]                     = Option(false, usi)
    o["MultiPV"]                     = Option(1, 1, 500, usi)
    o["Skill Level"]                 = Option(20, 0, 20, usi)
    o["Emergency Base Time"]         = Option(60, 0, 30000, usi)
    o["Emergency Move Time"]         = Option(30, 0, 5000, usi)
    o["Minimum Thinking Time"]       = Option(20, 0, 5000, usi)
    o["Slow Mover"]                  = Option(80, 10, 1000, usi)

    usi.is_callback_enable = true
    
    return o
end

function setindex!(omap::OptionMap, value::Option, key::String)
    if value.usi.is_callback_enable
        value.on_change(value)
    end
end

# Shogi Server
function producer(usi::USI, omap::OptionMap, host::ASCIIString, port::Int)
    err = 0
    server = listen(getaddrinfo(host), int(port))
    while true
        conn = accept(server)
        @async begin
            try
                while true
                    line = readline(conn)
                    chomp(line)
                    produce([line,conn])
                end
            catch err
                print("connection ended with error $err")
            end
        end
    end
    return err
end

# mainLoop comes here!
