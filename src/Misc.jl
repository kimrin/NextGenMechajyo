function engine_info(to_uci::Bool, game::Uint64)
    gamestr = (game == Chess) ? "Chess": "Shogi"

    if to_uci
        return string("id name Mecha Jyoshi $gamestr ",MECHAJYO_VERSION,"\n",
                      "id author Sayuri TAKEBE, Mio WATANABE, Miyuki SAKAI, Rieko TSUJI and Takeshi KIMURA\n")
    else
        return string("Mecha Jyoshi $gamestr ",MECHAJYO_VERSION,"\n",
                      "2014(c) by Sayuri TAKEBE, Mio WATANABE, Miyuki SAKAI, Rieko TSUJI and Takeshi KIMURA\n")
    end
end
