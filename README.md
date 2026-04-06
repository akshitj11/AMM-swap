# vyper-stableswap

![Vyper](https://img.shields.io/badge/Vyper-^0.3.10-purple)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-Titanoboa-blue)

A Curve-style stableswap AMM written entirely in Vyper. Two-token stable pools with near-zero slippage, LP tokens, and swap fees. No Solidity. No TypeScript. Pure Vyper.

---

## What is a Stableswap?

A regular Uniswap-style AMM uses the constant product formula `x·y=k`. This causes high slippage for large trades — even between stablecoins that should always be 1:1.

Curve's insight: blend a flat line `x+y=k` (zero slippage) with a hyperbola `x·y=k` (drain protection). The result is a curve that is **flat near the 1:1 price point** and only curves at the extremes.

```
         |
reserve  |  · · · · x·y=k (uniswap)
   y     | ————————— x+y=k (flat)
         | ——·—·——·— stableswap (ours) ← flat in the middle
         |
         +——————————————
              reserve x
```

The blend is controlled by the **amplification coefficient A**. Higher A = flatter curve = lower slippage.

---

## Project Structure

```
vyper-stableswap/
├── stable_swap.vy          # core AMM contract
├── lp_token.vy             # ERC-20 LP token
└── tests/
    ├── mock_erc20.vy       # fake stablecoin for testing
    └── test_stable_swap.py # Titanoboa test suite
```

---

## Contracts

### `stable_swap.vy`

The core AMM. Handles all pool logic.

| Function | Description |
|---|---|
| `add_liquidity(amount0, amount1)` | Deposit tokens, receive LP tokens |
| `remove_liquidity(lp_amount)` | Burn LP tokens, receive tokens back |
| `swap(token_in, amount_in)` | Swap one stablecoin for the other |
| `_get_D(x, y)` *(internal)* | Solve for total liquidity D via Newton's method |
| `_get_y(x_new, D)` *(internal)* | Solve for output reserve after swap |
| `_sqrt(x)` *(internal)* | Integer square root via Babylonian method |

### `lp_token.vy`

A standard ERC-20 token representing a user's share of the pool. Only `stable_swap.vy` can mint or burn — nobody else.

| Function | Description |
|---|---|
| `mint(to, amount)` | Create LP tokens — only callable by pool |
| `burn(to, amount)` | Destroy LP tokens — only callable by pool |
| `transfer(to, amount)` | Send LP tokens to another address |
| `approve(spender, amount)` | Approve someone to spend your LP tokens |
| `transferFrom(owner, to, amount)` | Spend approved LP tokens on behalf of owner |

---

## How Liquidity Works

```
1. approve stable_swap to spend your USDC + USDT
        ↓
2. call add_liquidity(amount0, amount1)
        ↓
3. pool pulls your tokens via transferFrom
        ↓
4. pool mints LP tokens to your wallet
        ↓
        ... traders use the pool, fees accumulate ...
        ↓
5. call remove_liquidity(lp_amount)
        ↓
6. pool burns your LP tokens
        ↓
7. you receive your share back + fees earned
```

Your LP tokens represent your **proportional share** of the pool. As swap fees accumulate, each LP token becomes redeemable for slightly more than you deposited.

---

## Deployment

Deploy `lp_token.vy` first, then pass its address to `stable_swap.vy`.

### `lp_token.vy` constructor

| Param | Description |
|---|---|
| `_name` | Token name e.g. `"Curve LP Token"` |
| `_symbol` | Token symbol e.g. `"CLP"` |
| `_decimals` | Decimals, typically `18` |
| `_minter` | Address of `stable_swap.vy` |

### `stable_swap.vy` constructor

| Param | Description |
|---|---|
| `_token0` | Address of first stablecoin e.g. USDC |
| `_token1` | Address of second stablecoin e.g. USDT |
| `_A` | Amplification coefficient e.g. `100` |
| `_fee` | Swap fee in basis points e.g. `3` = 0.03% |
| `_lp_token` | Address of deployed `lp_token.vy` |

---


---

## The Math

The stableswap invariant for a 2-token pool:

```
4A(x + y) + D = 4AD + D³ / 4xy
```

Where `x`, `y` are token reserves, `D` is total liquidity, and `A` is the amplification coefficient.

Solving for `D` and for output reserves after a swap requires iterative Newton's method — both implemented in `_get_D` and `_get_y`.

Fees are deducted from the output amount and kept in the pool, rewarding liquidity providers over time.

---



## By

- [Curve Finance](https://curve.fi) — original stableswap design
- [Uniswap V1](https://github.com/Uniswap/v1-contracts) — also written in Vyper
- [Vyper docs](https://docs.vyperlang.org)

---

## License

MIT
