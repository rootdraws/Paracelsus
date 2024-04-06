# RUGPOOL.MONEY

RUGPOOL is an crowdfunding platform for Fair-Launched Meme Tokens.

RUGFACTORY.sol is a factory pattern which permissionlessly allows users to launch tokens POOLWARDEN.sol contract.

Invoking the POOLWARDEN triggers the minting of your token. You have 24 Hours After Deployment to crowdfund the pool.

While you are spreading the word, the POOLWARDEN takes the following actions:

1) mintMaxSupply(ERC20) to POOLWARDEN
2) Accept ETH Contributions
3) Tracks PARTYMEMBER | CONTRIBUTION in an Array
4) Issues out 1 $TOKEN to each PARTYMEMBER
5) Records Campaign with RUGREGISTRY.sol
6) Tithes 1% into a SLOWRUG.sol 1 Year Linear Vesting Contract, which feeds into RUGFACTORY.SOL

After 24 Hours has passed, the PoolWarden holds a bunch of TOKEN and ETH.

## POOLWARDEN

The Following Functions can be called by any PARTYMEMBER:

* distribution()

1) 50% of Remaining TOKEN is airdropped pro-rata to contributors.
2) 50% of TOKEN is paired with 100% of ETH raised and deposited into a univ2 LP via [Supswap](https://supswap.xyz/v2/add/ETH/0xd988097fb8612cc24eeC14542bC03424c656005f).

* poolFees()

POOLWARDEN owns LP, and is earning 0.25% Fees. If these fees need to be manually claimed, TOKEN holders can do that.

* rageRug()

Three Weeks after distribution() is called, TOKEN holders can call the rageRug feature dissolve the holdings of the POOLWARDEN, and distribute pro-rata to TOKEN holders.

## RUGFACTORY

The 1% sent by the POOLWARDEN into the one year linear vesting contract drip feeds tokens into RUGFACTORY.sol

* rugpull()

rugpull() is a function that can be called by any $FACTORY holder. The rugpull() is adapted from the Moonbased Rovers.
The Function Market Sells the Tokens in the Hopper for ETH.
1% of the accumulated tokens is awarded to the caller of the function

* compoundLP()

compoundLP() is a function that can be called by any $FACTORY holder.
The ETH from a rugpull() is paired with FACTORY to build LP, which is owned by RUGFACTORY.sol
