function set_generation(tte::TTEntry, g::Uint8)
    tte.generation8 = g
end

function save(tte::TTEntry, k::Uint32, v::Value, b::Bound, d::Depth, m::SMove, g::Uint8, ev::Value)
    tte.key32 = k
    tte.move32 = m
    tte.bound8 = b
    tte.generation8 = g
    tte.value16 = v
    tte.depth16 = d
    tte.evalValue = ev
end

function new_search(bb::SContextBB)
    bb.generation += 1
end
