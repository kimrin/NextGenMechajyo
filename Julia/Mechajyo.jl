# Main of Mechajyo Module

module Mechajyo

importall Base

abstract UGI # Universal Game Interface: father of UCI, USI

export UCI, USI,
#functions
    engine_info

include("USI.jl")
include("UCI.jl")
include("Misc.jl")

###############################################################################
# Constants
const Chess = uint64(0xc0debeef)
const Shogi = uint64(0xcafebabe)
const MECHA_JYOSHI_SHOGI = int64(2)
const MECHAJYO_VERSION = "0.01"

export Chess, Shogi, MECHA_JYOSHI_SHOGI, MECHAJYO_VERSION
###############################################################################

##########################################################################
##########################################################################

end
