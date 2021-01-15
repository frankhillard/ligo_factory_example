// counter contract
type action_counter =
| Increment of int
| Decrement of int

type counter_storage = int

type full_counter_storage = {
  storage : counter_storage;
}

type full_counter_return = operation list * full_counter_storage

type create_counter_func = (key_hash option * tez * full_counter_storage) -> (operation * address)

// factory contract
type service_id = string

type storage = {
  services_list : service_id set;
  services : (service_id, address) map
}

type create_service_param = {
  name : service_id;
  initial_value : nat;
}

type full_factory_return = operation list * storage

type action =
| CreateService of create_service_param
| IncrementService of create_service_param
| DecrementService of create_service_param

let wrap_increment_trx(value : nat) : action_counter = 
  Increment(int(value))

let wrap_decrement_trx(value : nat) : action_counter = 
  Decrement(int(value))

let create_counter : create_counter_func =
[%Michelson ( {| { UNPPAIIR ;
                  CREATE_CONTRACT 
#include "counter.tz"
                  ;
                    PAIR } |}
           : create_counter_func)]

let increment_service (upd, store : create_service_param * storage) : full_factory_return = 
if Set.mem upd.name store.services_list then
  match Map.find_opt upd.name store.services with
  | Some a -> 
    let ci_opt : action_counter contract option = Tezos.get_contract_opt a in
    let ci : action_counter contract = match ci_opt with
    | Some addr -> addr
    | None -> (failwith("increment entrypoint not found") : action_counter contract)
    in
    let increment_action_call : action_counter = wrap_increment_trx(upd.initial_value) in
    let op : operation = Tezos.transaction increment_action_call 0mutez ci in 
    ([ op ], store)
  | None ->  (failwith("service not found") : full_factory_return)
else
  (failwith("service not launched") : full_factory_return)

let decrement_service (upd, store : create_service_param * storage) : full_factory_return = 
if Set.mem upd.name store.services_list then
  match Map.find_opt upd.name store.services with
  | Some a -> 
    let ci_opt : action_counter contract option = Tezos.get_contract_opt a in
    let ci : action_counter contract = match ci_opt with
    | Some addr -> addr
    | None -> (failwith("decrement entrypoint not found") : action_counter contract)
    in
    let decrement_action_call : action_counter = wrap_decrement_trx(upd.initial_value) in
    let op : operation = Tezos.transaction decrement_action_call 0mutez ci in 
    ([ op ], store)
  | None ->  (failwith("service not found") : full_factory_return)
else
  (failwith("service not launched") : full_factory_return)

let launch_service (addr, service_name, init_value, s : address * service_id * nat * storage) : full_factory_return =
  if Set.mem service_name s.services_list then 
    (failwith("service already launched") : full_factory_return)
  else 
  if Tezos.amount < 1mutez then 
    (failwith("requires 1 mutez to deploy a new counter service") : full_factory_return)
  else  
    let new_services_list = Set.add service_name s.services_list in 
    let service_storage : counter_storage = 0 in
    let res : (operation * address) = create_counter((None : key_hash option), Tezos.amount, { storage = service_storage }) in
    let new_services = Map.add service_name res.1 s.services in
    let operations : operation list = [ res.0 ] in 
    (operations, { s with services_list=new_services_list; services=new_services})

let create_service(serv, store : create_service_param * storage) : operation list * storage = 
  let result : full_factory_return = launch_service(Tezos.self_address, serv.name, serv.initial_value, store) in
  result

let main (p,s: action * storage) : full_factory_return =
   match p with
   | CreateService n -> create_service (n, s)
   | IncrementService i -> increment_service (i, s)
   | DecrementService d -> decrement_service (d, s)
