# Main of Mechajyo Module

module Mechajyo

importall Base

abstract UGI # Universal Game Interface: father of UCI, USI

const Chess = uint64(0xc0bebeef)
const Shogi = uint64(0xcafebabe)

type USI <: UGI
    game::Uint64
    is_callback_enable::Bool
    function USI(g::Uint64 = Shogi)
        new(g, false)
    end
end

type UCI <: UGI
    game::Uint64
    is_callback_enable::Bool
    function UCI(g::Uint64 = Chess)
        return new(g, false)
    end
end

export UCI, USI,
#functions
    engine_info, initialize

include("Types.jl")
include("RKiss.jl")
include("BitCount.jl")
include("BitBoards.jl")
include("Globals.jl")
include("Position.jl")

include("UCI.jl")
include("USI.jl")

include("Misc.jl")

###############################################################################
# Constants

const MECHA_JYOSHI_SHOGI = int64(2)
const MECHAJYO_VERSION = "0.01"

const MAX_THREADS = int64(64) # Because SplitPoint::slavesMask is a uint64_t
const MAX_SPLITPOINTS_PER_THREAD = int64(8)

export Chess, Shogi, MECHA_JYOSHI_SHOGI, MECHAJYO_VERSION, MAX_THREADS, MAX_SPLITPOINTS_PER_THREAD
export Context, ContextBB, initBB, mainLoop, OptionMap # type, functions

###############################################################################

end
