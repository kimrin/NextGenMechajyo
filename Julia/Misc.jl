function engine_info(to_uci::Bool, game::Uint64)
    gamestr = (game == Chess) ? "Chess": "Shogi"
    return string("id name Mecha Jyoshi $gamestr ",MECHAJYO_VERSION,"\n",
                  "id author Sayuri TAKEBE, Mio WATANABE, Miyuki SAKAI, Rieko TSUJI and Takeshi KIMURA\n")
end
