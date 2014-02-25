type UCI <: UGI
    game::Uint64
    function UCI(g::Uint64)
        return new(g)
    end
end

type Option
    defaultValue::String
    currentValue::String
    otype::String
    min::Int64
    max::Int64
    idx::Uint64 # I haven't seen where idx used
    on_change::Function
    uci::UCI
    
    function Option(v::Int64, minv::Int64, maxv::Int64, u::UCI, on_c::Function = on_callback_do_nothing)
        new( "$v", "$v", "spin", minv, maxv, uint64(0xdead), on_c, u)
    end
    function Option(v::String, u::UCI, on_c::Function = on_callback_do_nothing)
        new( v, v, "string", int64(0), int64(0), uint64(0xdead), on_c, u)
    end
    function Option(u::UCI, on_c::Function = on_callback_do_nothing)
        new( "", "", "button", int64(0), int64(0), uint64(0xdead), on_c, u)
    end
    function Option(v::Bool, u::UCI, on_c::Function = on_callback_do_nothing)
        de::String = v ? "true": "false"
        new( de, de, "check", int64(0), int64(0), uint64(0xdead), on_c, u)
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
    
    return o
end

function setindex!(omap::OptionMap, value::Option, key::String)
    value.on_change(value)
end
