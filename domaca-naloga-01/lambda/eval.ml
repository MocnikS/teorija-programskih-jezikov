module S = Syntax

let rec eval_exp = function
  | S.Var x -> failwith "Expected a closed term"
  | S.Int _ | S.Bool _ | S.Lambda _ | S.RecLambda _ | S.Nil as e -> e
  | S.Plus (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Int (n1 + n2)
  | S.Minus (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Int (n1 - n2)
  | S.Times (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Int (n1 * n2)
  | S.Equal (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Bool (n1 = n2)
  | S.Less (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Bool (n1 < n2)
  | S.Greater (e1, e2) ->
      let n1 = eval_int e1
      and n2 = eval_int e2
      in S.Bool (n1 > n2)
  | S.IfThenElse (e, e1, e2) ->
      begin match eval_exp e with
      | S.Bool true -> eval_exp e1
      | S.Bool false -> eval_exp e2
      | _ -> failwith "Boolean expected"
      end
  | S.Apply (e1, e2) ->
      let f = eval_exp e1
      and v = eval_exp e2
      in
      begin match f with
      | S.Lambda (x, e) -> eval_exp (S.subst [(x, v)] e)
      | S.RecLambda (f, x, e) as rec_f -> eval_exp (S.subst [(f, rec_f); (x, v)] e)
      | _ -> failwith "Function expected"
      end
  | S.Pair (e1, e2) -> S.Pair (eval_exp e1, eval_exp e2)
  | S.Cons (g,r) -> S.Cons (eval_exp g, eval_exp r)
  | S.Fst e ->
      begin match eval_exp e with
      | S.Pair (v1, v2) -> v1
      | _ -> failwith "Pair expected2"
      end
  | S.Snd e ->
      begin match eval_exp e with
      | S.Pair (v1, v2) -> v2
      | _ -> failwith "Pair expected1"
      end
  | S.Match (e1, e2, i1, i2, e) ->
      begin match eval_exp e1 with
      | S.Nil -> eval_exp e2
      | S.Cons (g, r) -> eval_exp (S.subst [ (i1, g); (i2, r) ] e)
      | _ -> failwith "List expected2"
      end
and eval_int e =
  match eval_exp e with
  | S.Int n -> n
  | _ -> failwith "Integer expected"
  

let rec is_value = function
  | S.Int _ | S.Bool _ | S.Lambda _ | S.RecLambda _ 
  | S.Nil -> true
  | S.Var _ | S.Plus _ | S.Minus _ | S.Times _ | S.Equal _ | S.Less _ | S.Greater _
  | S.IfThenElse _ | S.Apply _
  | S.Fst _ | S.Snd _ | S.Match _ -> false
  | S.Pair (v1, v2) -> (is_value v1 && is_value v2)
  | S.Cons (g, r) -> (is_value g && is_value r)


let rec step = function
  | S.Var _ | S.Int _ | S.Bool _ | S.Lambda _ | S.RecLambda _ -> failwith "Expected a non-terminal expression"
  | S.Plus (S.Int n1, S.Int n2) -> S.Int (n1 + n2)
  | S.Plus (S.Int n1, e2) -> S.Plus (S.Int n1, step e2)
  | S.Plus (e1, e2) -> S.Plus (step e1, e2)
  | S.Minus (S.Int n1, S.Int n2) -> S.Int (n1 - n2)
  | S.Minus (S.Int n1, e2) -> S.Minus (S.Int n1, step e2)
  | S.Minus (e1, e2) -> S.Minus (step e1, e2)
  | S.Times (S.Int n1, S.Int n2) -> S.Int (n1 * n2)
  | S.Times (S.Int n1, e2) -> S.Times (S.Int n1, step e2)
  | S.Times (e1, e2) -> S.Times (step e1, e2)
  | S.Equal (S.Int n1, S.Int n2) -> S.Bool (n1 = n2)
  | S.Equal (S.Int n1, e2) -> S.Equal (S.Int n1, step e2)
  | S.Equal (e1, e2) -> S.Equal (step e1, e2)
  | S.Less (S.Int n1, S.Int n2) -> S.Bool (n1 < n2)
  | S.Less (S.Int n1, e2) -> S.Less (S.Int n1, step e2)
  | S.Less (e1, e2) -> S.Less (step e1, e2)
  | S.Greater (S.Int n1, S.Int n2) -> S.Bool (n1 > n2)
  | S.Greater (S.Int n1, e2) -> S.Greater (S.Int n1, step e2)
  | S.Greater (e1, e2) -> S.Greater (step e1, e2)
  | S.IfThenElse (S.Bool b, e1, e2) -> if b then e1 else e2
  | S.IfThenElse (e, e1, e2) -> S.IfThenElse (step e, e1, e2)
  | S.Apply (S.Lambda (x, e), v) when is_value v -> S.subst [(x, v)] e
  | S.Apply (S.RecLambda (f, x, e) as rec_f, v) when is_value v -> S.subst [(f, rec_f); (x, v)] e
  | S.Apply ((S.Lambda _ | S.RecLambda _) as f, e) -> S.Apply (f, step e)
  | S.Apply (e1, e2) -> S.Apply (step e1, e2)
  | S.Pair (e1, e2) when (is_value e1 && is_value e2) -> failwith "Expected a non-terminal expression"
  | S.Pair (v1, e2) when (is_value v1) -> S.Pair (v1, step e2)
  | S.Pair (e1, e2) -> S.Pair (step e1, e2)
  | S.Nil -> failwith "Expected a non-terminal expression"
  | S.Cons (e1, e2) when (is_value e1 && is_value e2) -> failwith "Expected a non-terminal expression"
  | S.Cons (v1, e2) when (is_value v1) -> S.Cons (v1, step e2)
  | S.Cons (e1, e2) -> S.Cons (step e1, e2)
  | S.Fst (S.Pair (v1, v2)) when (is_value v1 && is_value v2) -> v1
  | S.Fst _ -> failwith "Expected a non-terminal expression"
  | S.Snd (S.Pair (v1, v2)) when (is_value v1 && is_value v2) -> v2
  | S.Snd _ -> failwith "Expected a non-terminal expression"
  | S.Match (e1, e2, i1, i2, e) when is_value e1 ->
    begin match e1 with
    | S.Nil -> e2
    | S.Cons (v1,v2) -> S.subst [ (i1, v1); (i2, v2)] e
    | _ -> failwith "Expected a list"
    end
  | S.Match (e1, e2, i1, i2, e) -> S.Match (step e1, e2, i1, i2, e)


let big_step e =
  let v = eval_exp e in
  print_endline (S.string_of_exp v)

let rec small_step e =
  print_endline (S.string_of_exp e);
  if not (is_value e) then
    (print_endline "  ~>";
    small_step (step e))