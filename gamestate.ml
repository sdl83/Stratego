(* Gamestate mli *)
type location = int * int
type piece =
  | Flag
  | Bomb
  | Spy of int
  | Scout of int
  | Marshal of int
  | General of int
  | Miner of int
  | Colonel of int
  | Major of int
  | Captain of int
  | Lieutenant of int
  | Sergeant of int
  | Corporal of int

and player = {name: bytes; pieces: (piece*location) list; graveyard: piece list}

(*function that gets rank of the piece so that in attack, it can match on the rankings.
get_rank keep in mind flag and bomb*)

(* piece is the piece in that location with the string of the player,
* None if location is empty *)
and game_board = (location*((piece*player) option)) list

and gamestate = {gb: game_board ; human: player; comp: player; turn: string}

(* Initializes game state from user input and computer generated setup *)
let new_game location piece gamestate  = failwith "unimplemented"

(* Uses player assocation pieces record to get the location of a piece
get location. try with, and check if that piece is in the player's piece to chekc
if my piece is actually on the board.*)
let get_location  player  piece  = failwith "unimplemented"

let validate_move game_board player piece location = failwith "unimplemented"

(*check if its a flag or bomb before i call get_rank.
if bomb && miner, then miner moves to that piece and bomb leaves
otherwise piece leaves and bomb leaves too.
and then the three cases of rankings. if flag, then win the game.

piece1 is my piece
piece2 is the piece that was on the tile. *)
let attack piece1 piece2 = failwith "unimplemented"


let remove_from_board game_board player piece location =
  let new_player_pieces =
    (List.filter
      (fun (pce,(col,row)) ->
        pce<>piece || (col,row)<>location
      )
      player.pieces
    )
  in
  let new_player_1 = {player with pieces=new_player_pieces} in
  let new_player_2 = {new_player_1 with graveyard=piece::player.graveyard} in
  let new_game_board =
    (List.map
      (fun ((col,row),some_piece) ->
        if (col,row)=location then
          ((col,row),None)
        else
          (match some_piece with
            | None -> ((col,row),some_piece)
            | Some (pce,_) -> ((col,row),Some (pce,new_player_2))
          )
      )
      game_board)
  in
  (new_game_board,new_player_2)

let rec remove_first_from_list piece lst =
  match lst with
  | [] -> []
  | h::t -> if h=piece then t else h::remove_first_from_list piece t

let add_to_board game_board player piece location =
  let new_graveyard = remove_first_from_list piece player.graveyard in
  let new_player_pieces =
    (List.map
      (fun (pce,(col,row)) ->
        if pce=piece then
          (pce,location)
        else
          (pce,(col,row))
      )
    player.pieces
  )
  in
  let new_player_1 = {player with pieces=new_player_pieces} in
  let new_player_2 = {new_player_1 with graveyard=new_graveyard} in
  let new_gameboard =
    (List.map
      (fun ((col,row),some_piece) ->
        if (col,row)=location then
          ((col,row),Some (piece,new_player_2))
        else
          (match some_piece with
          | None -> ((col,row),some_piece)
          | Some (pce,_) -> ((col,row),Some (pce, new_player_2))))
      game_board)
  in
  (new_gameboard, new_player_2)

(* returns a new gamestate with updated piece locations
* - [gamestate] is the current gamestate to be updated
* - [player] is the current player
* - [piece] is the piece to try to move
* - [location] is the desired end location
* Calls get_location to get the current location of the pice
* Calls validate_move to verify that that piece can move to the end location
* If validate_move returns true with no piece,
*   update game state with the current piece
* If validate_move returns true with some piece,
*   calls attack function and updates board
* If validate_move returns false,
*   asks player to try a different move *)
let move gamestate player piece end_location =
  let start_location = get_location player piece in
  let game_board = gamestate.gb in
  match validate_move game_board player piece end_location with
  | (true, Some opp_piece) ->
      (match attack piece opp_piece with
      | None ->
          let (removed_start_gb, new_player) = remove_from_board game_board
                                                player piece start_location in
          let (removed_end_gb, new_opp_player) = remove_from_board
                                                removed_start_gb new_player
                                                opp_piece end_location in
          let changed_gs = {gamestate with gb = removed_end_gb} in
          let new_gs =
            (if player.name = "human" then
              {changed_gs with human = new_player; comp = new_opp_player}
            else
              {changed_gs with human = new_opp_player; comp = new_player})
          in
          (true, new_gs)
      | Some pce -> failwith "TODO"
(*           let (removed_start_gb, new_player) = remove_from_board game_board
                                                player piece start_location in
          let (add_end_gb, newer_player) = add_to_board removed_start_gb
                                            newer_player *)
      )

  | (true, None) ->
      let (removed_gb,new_player) = remove_from_board game_board player
                                      piece start_location
      in
      let (added_gb,newer_player) = add_to_board removed_gb new_player
                                      piece end_location
      in
      if player.name="human" then
        (true,{gamestate with gb = added_gb; human = newer_player})
      else
        (true,{gamestate with gb = added_gb; comp = newer_player})
  | (false, _) -> (false, gamestate)


let piece_to_string (piece:piece) =
  match piece with
  | Flag -> "Fla"
  | Bomb -> "Bom"
  | Spy x -> "Spy"
  | Scout x -> "Sco"
  | Marshal x -> "Mar"
  | General x -> "Gen"
  | Miner x -> "Min"
  | Colonel x -> "Col"
  | Major x -> "Maj"
  | Captain x -> "Cap"
  | Lieutenant x -> "Lie"
  | Sergeant x -> "Ser"
  | Corporal x -> "Cor"

let rec print_game_board (game_board:game_board)=
  match game_board with
  | [] -> ()
  | ((col,row),some_piece)::t ->
    let s1 =
      (match some_piece with
      | None -> "   "
      | Some (piece,player) ->
          if player.name="human" then
            (piece_to_string piece)
          else
            "XXX")
    in
    let s2 =
      (if col=1 && row!=10 then
        "     "^
        "-------------------------------------------------------------\n  "^
        (string_of_int row)^"  | "^s1^" |"
      else if col=1 && row=10 then
        "     "^
        "-------------------------------------------------------------\n "^
        (string_of_int row)^"  | "^s1^" |"
      else if col=10 then
        " "^s1^" |\n"
      else
        " "^s1^" |")
    in
    let s3 =
      (if row=1 && col=10 then
        s2^
        "     -------------------------------------------------------------\n"
      else
        s2
      )
    in
    Printf.printf "%s" s3;
    print_game_board t

let print_gamestate (gamestate:gamestate) =
  print_game_board gamestate.gb;
  Printf.printf
    "        1     2     3     4     5     6     7     8     9    10\n\n";



