# Main of Mechajyo Module

module Mechajyo

importall Base

abstract UGI # Universal Game Interface: father of UCI, USI

export UCI, USI,
#functions
    engine_info, initialize


include("USI.jl")
include("UCI.jl")
include("Misc.jl")

###############################################################################
# Constants

const Chess = uint64(0xc0bebeef)
const Shogi = uint64(0xcafebabe)
const MECHA_JYOSHI_SHOGI = int64(2)
const MECHAJYO_VERSION = "0.01"

const MAX_THREADS = int64(64) # Because SplitPoint::slavesMask is a uint64_t
const MAX_SPLITPOINTS_PER_THREAD = int64(8)

include("Types.jl")
include("RKiss.jl")
include("BitCount.jl")
include("BitBoards.jl")
include("Globals.jl")

export Chess, Shogi, MECHA_JYOSHI_SHOGI, MECHAJYO_VERSION, MAX_THREADS, MAX_SPLITPOINTS_PER_THREAD
export Context, ContextBB, init

###############################################################################

##########################################################################
##########################################################################

module test
end

end
