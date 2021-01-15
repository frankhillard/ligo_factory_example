# ligo_factory_exemple

This repository provides an example of a Tezos smart contract implementing a "factory" pattern. The smart contract is written in Ligo (cameligo).

The smart contract possess the following entry points:

* CreateService : Deploy a Counter smart contract and register it into mapping (inside the storage). An alias is associated to this counter contract. (the initial value of the counter must be specified).
* IncrementService : Calls the Increment entry point of a counter smart contract. (the alias of the counter smart contract must be specified, and the increment value argument too)



## Command lines

### Simulation with LIGO

The following command compiles the ligo smart contract

```
ligo compile-contract factory.mligo main
```

Save the michelson code with :
```
ligo compile-contract factory.mligo main > factory.tz
```



In order to verify our smart contract, we can deploy and test it on a sandbox environnement. The origination of the factory smart contract requires the initil storage state as a michelson expression. The initil storage can be compiled with the following command.

```
ligo compile-storage factory.mligo main '{ services_list=(Set.empty:string set); services=(Map.empty:(string,address)map)}'
```
It produces this expression (that will be used when deploying the smart contract):
```
(Pair {} {})
```

When we will be testing our smart contract we will need to prepare the invocation of an entry point and specify it arguments. For example, the following commands provides the michelson expression for its entrypoints invocation.  

For CreateService entry point
```
ligo compile-parameter factory.mligo main 'CreateService({name="A";initial_value=2n})'
```

For CreateService entry point
```
ligo compile-parameter factory.mligo main 'IncrementService({name="A";initial_value=5n})'
```

We can simulate the call of CreateService entry point with the following command:
```
ligo dry-run --amount=0.0001 factory.mligo main 'CreateService({name="A";initial_value=2n})' '{ services_list=(Set.empty:string set); services=(Map.empty:(string,address)map)}'
```

This last command may fail due to the fact that there is no deployment support during simulation in LIGO. We need a test this on a Tezos node.

### Deploy and test on a sandbox node

Setup of a Tezos sandbox envirronnment requires to install [Tezos from sources](https://tezos.gitlab.io/introduction/howtoget.html) and launch a node in [sandbox mode](https://tezos.gitlab.io/user/sandbox.html).

The following command deploys a factory smart contract with the initial storage prepared previously. The option --dry-run allows to simulate the deployment and indicates the amount of gas required.  

```
tezos-client originate contract factorycounter transferring 1 from bootstrap1 running '/home/frank/ligo/factory/factory.tz' --init '(Pair {} {})' --dry-run 
```

```
tezos-client originate contract factorycounter transferring 1 from bootstrap1 running '/home/frank/ligo/factory/factory.tz' --init '(Pair {} {})' --burn-cap 1.01
```


In another terminal, initializes a tezos client
```
cd tezos
eval `./src/bin_client/tezos-init-sandboxed-client.sh 1`
```

The following command bakes the pending transaction :
```
tezos-client bake for bootstrap1
```

Once the smart contract is deployed, we can check its address with :
```
tezos-client list known contracts
```

The factory address (in my example is KT1BF2rgxHgcyxNBaYMcdngNEo5WEssKVpbF). As you can see contract address start with "KT1" and accounts start with "tz1".

The storage associated to this factory contract can be retrieved with following command line :
```
tezos-client get contract storage for factorycounter
```

### Using our factory smart contract

Simulate entry point invocation with :
```
tezos-client transfer 0 from bootstrap3 to factorycounter --arg '(Left (Pair 2 "A"))' --dry-run
```

```
tezos-client transfer 0 from bootstrap3 to factorycounter --arg '(Right (Pair 5 "A"))' --dry-run
```

We can verify that counter smart contracts have been deployed by checking the factory storage
```
tezos-client get contract storage for factorycounter5
```
It produces :
```
Pair { Elt "A" "KT1MbpDddjYx8ZFH7irqHzAZ4S3ZHn2eNzjm" ;
       Elt "B" "KT1AEzZXCuCrMtArW6iQ3n7ejvSJ21DP8NLD" }
     { "A" ; "B" }
```

It is possible to interact directly with one of the counters

```
tezos-client get contract storage for KT1AEzZXCuCrMtArW6iQ3n7ejvSJ21DP8NLD
```

```
tezos-client transfer 0 from bootstrap1 to KT1AEzZXCuCrMtArW6iQ3n7ejvSJ21DP8NLD --arg '(Right 2)'
```

```
tezos-client transfer 0 from bootstrap1 to KT1AEzZXCuCrMtArW6iQ3n7ejvSJ21DP8NLD --arg '(Left 2)'
```