module Amb = AmbInterp
module A = Ast
module S = Sast
module T = Tast

exception Valor_de_retorno of T.expressao

let obtem_nome_tipo_var exp = let open T in
  match exp with
  | ExpVar (v,tipo) ->
    (match v with
      | A.VarSimples (nome,_) -> (nome,tipo)
    )
  | _ -> failwith "obtem_nome_tipo_var: nao eh variavel"

let pega_int exp =
  match exp with
  |  T.ExpInt (i,_) -> i
  | _ -> failwith "pega_int: nao eh inteiro"

let pega_float exp =
  match exp with
  |  T.ExpReal (i,_) -> i
  | _ -> failwith "pega_float: nao eh float"

let pega_string exp =
  match exp with
  |  T.ExpString (s,_) -> s
  | _ -> failwith "pega_string: nao eh string"

let pega_char exp =
  match exp with
  |  T.ExpChar (i,_) -> i
  | _ -> failwith "pega_char: nao eh caracter"

let pega_bool exp =
  match exp with
  |  T.ExpBool (b,_) -> b
  | _ -> failwith "pega_bool: nao eh booleano"

type classe_op = Aritmetico | Relacional | Logico | Cadeia

let classifica op =
  let open A in
  match op with
   And
  | Or -> Logico
  | Mais
  | Menos
  | Mult
  | Div
  | Mod
  | Expoente -> Aritmetico
  | Menor
  | Maior
  | MenorIgual
  | Igual
  | MaiorIgual
  | Difer -> Relacional
  | Concat -> Cadeia
  

let rec interpreta_exp amb exp =
let open A in
let open T in

  match exp with
  | ExpVoid
  | ExpInt _
  | ExpString _
  | ExpChar _
  | ExpReal _
  | ExpBool _   -> exp
  | ExpVar _ ->
    let (id,tipo) = obtem_nome_tipo_var exp in
    (* Tenta encontrar o valor da variável no escopo local, se não      *)
    (* encontrar, tenta novamente no escopo que engloba o atual. Prossegue-se *)
    (* assim até encontrar o valor em algum escopo englobante ou até    *)
    (* encontrar o escopo global. Se em algum lugar for encontrado,         *)
    (* devolve-se o valor. Em caso contrário, devolve uma exceção       *)
    (match (Amb.busca amb id) with
     | Amb.EntVar (tipo, v) ->
       (match v with
        | None -> failwith ("variável nao inicializada: " ^ id)
        | Some valor -> valor
       )
     |  _ -> failwith "interpreta_exp: expvar"
    )
  | ExpOp ((op,top), (esq, tesq), (dir,tdir)) ->
    let  vesq = interpreta_exp amb esq
    and vdir = interpreta_exp amb dir in

    let interpreta_aritmetico () =
      (match tesq with
       | TipoInt ->
         (match op with
          | Mais  -> ExpInt (pega_int vesq + pega_int vdir, top)
          | Menos -> ExpInt (pega_int vesq - pega_int vdir, top)
          | Mult  -> ExpInt (pega_int vesq * pega_int vdir, top)
          | Div   -> ExpInt (pega_int vesq / pega_int vdir, top)
          | _ -> failwith "interpreta_aritmetico"
         )
       | TipoReal ->
         (match op with
          | Mais  -> ExpReal (pega_float vesq +. pega_float vdir, top)
          | Menos -> ExpReal (pega_float vesq -. pega_float vdir, top)
          | Mult  -> ExpReal (pega_float vesq *. pega_float vdir, top)
          | Div   -> ExpReal (pega_float vesq /. pega_float vdir, top)
          | _ -> failwith "interpreta_aritmetico"
         )
       | _ -> failwith "interpreta_aritmetico"
      )

    and interpreta_relacional () =
      (match tesq with
       | TipoInt ->
         (match op with
          | Menor -> ExpBool (pega_int vesq < pega_int vdir, top)
          | MenorIgual -> ExpBool (pega_int vesq <= pega_int vdir, top)
          | Maior  -> ExpBool (pega_int vesq > pega_int vdir, top)
          | MaiorIgual  -> ExpBool (pega_int vesq >= pega_int vdir, top)
          | Igual   -> ExpBool (pega_int vesq == pega_int vdir, top)
          | Difer   -> ExpBool (pega_int vesq != pega_int vdir, top)
          | _ -> failwith "interpreta_relacional int"
         )
       | TipoReal ->
         (match op with
          | Menor -> ExpBool (pega_float vesq < pega_float vdir, top)
          | MenorIgual -> ExpBool (pega_float vesq <= pega_float vdir, top)
          | Maior  -> ExpBool (pega_float vesq > pega_float vdir, top)
          | MaiorIgual  -> ExpBool (pega_float vesq >= pega_float vdir, top)
          | Igual   -> ExpBool (pega_float vesq == pega_float vdir, top)
          | Difer   -> ExpBool (pega_float vesq != pega_float vdir, top)
          | _ -> failwith "interpreta_relacional f"
         )
       | TipoString ->
         (match op with
          | Menor -> ExpBool (pega_string vesq < pega_string vdir, top)
          | Maior  -> ExpBool (pega_string vesq > pega_string vdir, top)
          | Igual   -> ExpBool (pega_string vesq == pega_string vdir, top)
          | Difer   -> ExpBool (pega_string vesq != pega_string vdir, top)
          | _ -> failwith "interpreta_relacional"
         )
       | TipoBool ->
         (match op with
          | Menor -> ExpBool (pega_bool vesq < pega_bool vdir, top)
          | Maior  -> ExpBool (pega_bool vesq > pega_bool vdir, top)
          | Igual   -> ExpBool (pega_bool vesq == pega_bool vdir, top)
          | Difer   -> ExpBool (pega_bool vesq != pega_bool vdir, top)
          | _ -> failwith "interpreta_relacional"
         )
       | _ ->  failwith "interpreta_relacional"
      )

    and interpreta_logico () =
      (match tesq with
       | TipoBool ->
         (match op with
          | Or -> ExpBool (pega_bool vesq || pega_bool vdir, top)
          | And ->   ExpBool (pega_bool vesq && pega_bool vdir, top)
          | _ ->  failwith "interpreta_logico"
         )
       | _ ->  failwith "interpreta_logico"
      )
    and interpreta_cadeia () =
      (match tesq with
       | TipoString ->
         (match op with
          | Concat -> ExpString (pega_string vesq ^ pega_string vdir, top)
          | _ ->  failwith "interpreta_cadeia"
         )
       | _ ->  failwith "interpreta_cadeia"
      )
      in
    let valor = (match (classifica op) with
          Aritmetico -> interpreta_aritmetico ()
        | Logico -> interpreta_logico ()
        | Relacional -> interpreta_relacional ()
        | Cadeia -> interpreta_cadeia ()
      )
    in
      valor  


  | ExpChamada (id, args, tipo) ->
    let open Amb in
    ( match (Amb.busca amb id) with
      | Amb.EntFun {tipo_fn; formais; locais; corpo} ->
           (* Interpreta cada um dos argumentos *)
           let vargs = List.map (interpreta_exp amb) args in
           (* Associa os argumentos aos parâmetros formais *)
           let vformais = List.map2 (fun (n,t) v -> (n, t, Some v)) formais vargs
           in interpreta_fun amb id vformais locais corpo
      | _ -> failwith "interpreta_exp: expchamada"
    )

and interpreta_fun amb fn_nome fn_formais fn_locais fn_corpo =
  let open A in
 (* Estende o ambiente global, adicionando um ambiente local *)
  let ambfn = Amb.novo_escopo amb in
   let insere_local  d =
    match d with
      (DecVar (v,t)) -> Amb.insere_local ambfn (fst v)  t None
  in
  (* Associa os argumentos aos parâmetros e insere no novo ambiente *)
  let insere_parametro (n,t,v) = Amb.insere_param ambfn n t v in
  let _ = List.iter insere_parametro fn_formais in
  (* Insere as variáveis locais no novo ambiente *)
    let _ = List.iter insere_local fn_locais in
    (* Interpreta cada comando presente no corpo da função usando o novo
       ambiente *)
  try
    let _ = List.iter (interpreta_cmd ambfn) fn_corpo in T.ExpVoid
    with
       Valor_de_retorno expret -> expret

and interpreta_cmd amb cmd =
  let open A in
  let open T in
  match cmd with
    CmdRetorno exp ->
    (* Levantar uma exceção foi necessária pois, pela semântica do comando de
        retorno, sempre que ele for encontrado em uma função, a computação
        deve parar retornando o valor indicado, sem realizar os demais comandos.
    *)
    (match exp with
     (* Se a função não retornar nada, verifica se ela foi declarada como void *)
       None -> raise (Valor_de_retorno ExpVoid)
     | Some e ->
       (* Avalia a expressão e retorne o resultado *)
       let e1 = interpreta_exp amb e in
       raise (Valor_de_retorno e1)
    )
  | CmdSe (teste, entao, senao) ->
    let teste1 = interpreta_exp amb teste in
   (match teste1 with
       ExpBool (true,_) ->
       (* Interpreta cada comando do bloco 'então' *)
       List.iter (interpreta_cmd amb) entao
     | _ ->
       (* Interpreta cada comando do bloco 'senão', se houver *)
       (match senao with
          None -> ()
        | Some bloco -> List.iter (interpreta_cmd amb) bloco
       )
    )

  | CmdAtrib (elem, exp) ->
    (* Interpreta o lado direito da atribuição *)
    let exp = interpreta_exp amb exp
    (* Faz o mesmo para o lado esquerdo *)
    and (elem1,tipo) = obtem_nome_tipo_var elem in
    Amb.atualiza_var amb elem1 tipo (Some exp)

  | ComandoExpress exp -> ignore( interpreta_exp amb exp)

  | CmdEntrada exp ->
    (* Obtem os nomes e os tipos de cada um dos argumentos *)
    let nts = obtem_nome_tipo_var exp in
    let leia_var (nome,tipo) =
      let valor =
        (match tipo with
         | A.TipoInt    -> T.ExpInt    (read_int (),   tipo)
         | A.TipoString -> T.ExpString (read_line (),  tipo)
         | A.TipoReal  -> T.ExpReal  (read_float (), tipo)
         | A.TipoChar   ->let str = (read_line ()).[0] in T.ExpChar   (str,  tipo)
         | _ -> failwith "leia_var: nao implementado"
        )
      in  Amb.atualiza_var amb nome tipo (Some valor)
    in
    (* Lê o valor para cada argumento e atualiza o ambiente *)
    leia_var nts

  | CmdEntrada exps ->
    let _ = interpreta_cmd amb (CmdEntrada exps) in
      print_newline()

  | CmdSaida exps ->
    (* Interpreta cada argumento da função 'saida' *)
    let exps = List.map (interpreta_exp amb) exps in
    let imprima exp =
      (match exp with
       | T.ExpInt (n,_) ->      let _ = print_int n in print_string " "
       | T.ExpString (s,_) -> let _ = print_string s in print_string " "
       | T.ExpBool (b,_) ->
         let _ = print_string (if b then "true" else "false")
         in print_string " "
       | _ -> failwith "imprima: nao implementado"
      )
    in
    let _ = List.iter imprima exps in
    print_newline ()

  | CmdSaida exps ->
    (* Interpreta cada argumento da função 'saida' *)
    let exps = List.map (interpreta_exp amb) exps in
    let imprima exp =
      (match exp with
       | T.ExpInt (n,_) ->      let _ = print_int n in print_string " "
       | T.ExpString (s,_) -> let _ = print_string s in print_string " "
       | T.ExpBool (b,_) ->
         let _ = print_string (if b then "true" else "false")
         in print_string " "
       | _ -> failwith "imprima: nao implementado"
      )
    in
    let _ = List.iter imprima exps in
    let _ = print_newline () in 
      print_newline ()
  
   
  | CmdWhile (teste, doit) ->
     let teste1 = interpreta_exp amb teste in
   (match teste1 with
       ExpBool (true,_) ->
       (* Interpreta uma iteraçao comando do corpo do while *)
       let _ = List.iter (interpreta_cmd amb) doit in 
       (* interpreta recursivamente as possíveis demais iterações do comando *)
        interpreta_cmd amb (CmdWhile (teste, doit))
       | _ -> ()
   )

  | CmdCase (teste, cases, senao) ->
     let teste1 = interpreta_exp amb teste in
    let rec match_cases listacase = ( match listacase with 
      head::tail ->
      (* Percorre a lista de cases *)
      (match head with Case (l,c) ->
      (* se a expressao do case for igual 
      a expressao do comando swith, então*)
       if (interpreta_exp amb l) = teste1 then 
        (* avalie cada comando desse case *)
        List.iter (interpreta_cmd amb) c
        (*caso não sejam iguais, avalie o próximo case*)
        else match_cases tail )
        (* se alcançou o fim da lista, é porque não acho nenhum case compatível,
        logo, hora de executar o bloco default*)
      | [] ->( match senao with 
        Some c -> 
        List.iter (interpreta_cmd amb) c
        (* não sei de um comando return em Ocaml,
         acredito que esse seja o jeito correto*)
        | None -> ignore()) )
    in match_cases cases

    | CmdFor (variavel, exp, condicao, var,inc, doit) ->
    let _ = interpreta_cmd amb (CmdAtrib (variavel, exp)) in
    (* let inc = interpreta_cmd amb (CmdAtrib (var, inc)) in *)
    let inc = CmdAtrib (var, inc) in
    interpreta_cmd amb (CmdWhile (condicao, List.append doit [inc]))
  

let insere_declaracao_var amb dec =
    match dec with
        A.DecVar (nome, tipo) ->  Amb.insere_local amb (fst nome) tipo None

let insere_declaracao_fun amb dec =
  let open A in
    match dec with
      Funcao {fn_nome; fn_tiporet; fn_formais; fn_locais; fn_corpo} ->
        let nome = fst fn_nome in
        let formais = List.map (fun (n,t) -> ((fst n), t)) fn_formais in
        Amb.insere_fun amb nome formais fn_locais fn_tiporet fn_corpo


(* Lista de cabeçalhos das funções pré definidas *)
let fn_predefs = let open A in [
    ("entrada", [("x", TipoInt); ("y", TipoInt)], TipoVoid, []);
    ("saida",     [("x", TipoInt); ("y", TipoInt)], TipoVoid, []);
]

(* insere as funções pré definidas no ambiente global *)
let declara_predefinidas amb =
  List.iter (fun (n,ps,tr,c) -> Amb.insere_fun amb n ps [] tr c) fn_predefs

let interprete ast =
  (* cria ambiente global inicialmente vazio *)
  let amb_global = Amb.novo_amb [] in
  let _ = declara_predefinidas amb_global in
  let (A.Programa ( decs_globais, decs_funs, corpo)) = ast in
  let _ = List.iter (insere_declaracao_var amb_global) decs_globais in
  let _ = List.iter (insere_declaracao_fun amb_global) decs_funs in
  (* Interpreta a função principal *)
  let resultado = List.iter (interpreta_cmd amb_global) corpo in
  resultado

