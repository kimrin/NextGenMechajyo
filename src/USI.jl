type USI <: UGI
    game::Uint64
    is_callback_enable::Bool
    function USI(g::Uint64)
        new(g, false)
    end
end

function initialize(usi::USI)
    None
end
