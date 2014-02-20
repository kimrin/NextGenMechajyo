type USI <: UGI
    game::Uint64
    function USI(g::Uint64)
        game = g
    end
end
