type UCI <: UGI
    game::Uint64
    function UCI(g::Uint64)
        game = g
    end
end
